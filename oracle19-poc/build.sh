#!/usr/bin/env bash
# =====================================================================
# build.sh — Construye la imagen distribuible con la base ya instalada
#
#   ./build.sh 1.0.0                 imagen base (sin ORDS)
#   ./build.sh 1.1.0 --ords          + ORDS, SIN APEX
#   ./build.sh 1.1.0 --ords-apex     + ORDS + APEX runtime
#
# Produce:
#   - imagen  oracle19c-grl[-ords|-ords-apex]:<version>
#   - archivo dist/oracle19c-grl[-ords|-ords-apex]-<version>.tar.gz
#
# Las tres salen de los MISMOS scripts de setup/. Las variantes con
# ORDS agregan install_ords.sh despues de install.sh, nada mas.
#
# Tarda ~30 min la base, ~35 con ORDS y ~55 con APEX. Es el precio de
# que despues arranque en 1-3 min en la maquina de cada persona.
#
# Las variantes con ORDS necesitan antes, una sola vez:
#   bash ords/descargar.sh && bash ords/construir_base.sh
#
# Si el paso 5 o 6 falla (p. ej. disco lleno durante el commit), no hay
# que rehacer la base: agregar --reanudar retoma desde el paso 5 sobre
# el contenedor ya verificado y apagado.
#   ./build.sh 1.1.0 --ords --reanudar
#
# En un servidor compartido (docker-prod), limitar la memoria del
# contenedor. Sin swap extra salvo que se pida con MEMSWAP_LIMIT:
#   MEM_LIMIT=4g ./build.sh 1.0.0
#
# Se corre desde WSL/Git Bash en la carpeta oracle19-poc/, o en Linux.
# =====================================================================

set -euo pipefail

VERSION="${1:-}"
VARIANTE="${2:-}"
REANUDAR="no"
if [ "$VARIANTE" = "--reanudar" ]; then VARIANTE=""; REANUDAR="si"; fi
[ "${3:-}" = "--reanudar" ] && REANUDAR="si"
if [ -z "$VERSION" ]; then
  echo "Uso: ./build.sh <version> [--ords | --ords-apex] [--reanudar]    (ej: ./build.sh 1.1.0 --ords)"
  exit 1
fi

case "$VARIANTE" in
  "")
    NOMBRE="oracle19c-grl";           COMPOSE="compose.build.yaml"
    CONT="oracle19-build";            LOGDIR="logs"
    ORDS="no";  WITH_APEX="false"
    DESC="Oracle 19c SE2 + GENERALIDADES + fixture 1000 personas" ;;
  --ords)
    NOMBRE="oracle19c-grl-ords";      COMPOSE="compose.build.ords.yaml"
    CONT="oracle19-build-ords";       LOGDIR="logs/ords"
    ORDS="si";  WITH_APEX="false";    DB_PORT=1524; ORDS_PORT=8082
    DESC="Oracle 19c SE2 + GENERALIDADES + ORDS, sin APEX" ;;
  --ords-apex)
    NOMBRE="oracle19c-grl-ords-apex"; COMPOSE="compose.build.ords.yaml"
    CONT="oracle19-build-ords-apex";  LOGDIR="logs/ords-apex"
    ORDS="si";  WITH_APEX="true";     DB_PORT=1525; ORDS_PORT=8083
    DESC="Oracle 19c SE2 + GENERALIDADES + ORDS + APEX runtime" ;;
  *)
    echo "Variante desconocida: $VARIANTE   (usar --ords o --ords-apex)"
    exit 1 ;;
esac

IMAGE="${NOMBRE}:${VERSION}"
PROJ="$CONT"
DIST="dist"
# Las lee compose.build.ords.yaml.
export CONT LOGDIR WITH_APEX DB_PORT="${DB_PORT:-}" ORDS_PORT="${ORDS_PORT:-}"
# Las leen los dos compose de build. Con MEM_LIMIT y sin MEMSWAP_LIMIT,
# memswap = memoria: el contenedor no usa swap.
export MEM_LIMIT="${MEM_LIMIT:-0}"
export MEMSWAP_LIMIT="${MEMSWAP_LIMIT:-$MEM_LIMIT}"

banner() {
  echo
  echo "====================================================================="
  echo "  $1"
  echo "====================================================================="
}

limpiar() {
  docker compose -p "$PROJ" -f "$COMPOSE" down 2>/dev/null || true
}

# GET contra el ORDS del contenedor. Imprime la respuesta HTTP completa
# (linea de estado, cabeceras y cuerpo). Usa /dev/tcp de bash porque la
# imagen de Oracle Linux 7 slim no trae curl garantizado, y hacerlo
# desde adentro evita depender de como cada Docker publica los puertos.
http_get() {
  docker exec "$CONT" bash -c '
    exec 3<>/dev/tcp/127.0.0.1/8080 || exit 1
    printf "GET %s HTTP/1.0\r\nHost: localhost\r\nConnection: close\r\n\r\n" "$1" >&3
    timeout 30 cat <&3' _ "$1" 2>/dev/null
}
http_codigo() { head -1 | awk '{print $2}'; }

if [ "$REANUDAR" = "si" ]; then
  banner "Reanudando desde el paso 5 ($IMAGE)"
  # Solo es seguro congelar un contenedor que paso la verificacion
  # (paso 3) y quedo apagado limpio (paso 4). Si no, se aborta.
  ESTADO=$(docker inspect -f '{{.State.Status}}' "$CONT" 2>/dev/null || echo "no existe")
  if [ "$ESTADO" != "exited" ]; then
    echo "ERROR: el contenedor $CONT esta '$ESTADO'; tiene que estar detenido. Corre el build completo."
    exit 1
  fi
  MARCA="$LOGDIR/INSTALL_OK"; [ "$ORDS" = "si" ] && MARCA="$LOGDIR/ORDS_OK"
  if [ ! -f "$MARCA" ]; then
    echo "ERROR: falta $MARCA: ese contenedor no paso la verificacion. Corre el build completo."
    exit 1
  fi
  # El SHUTDOWN del paso 4 va por docker exec y no queda en docker logs.
  # Lo que si queda: al llegar el SIGTERM de 'docker stop', runOracle.sh
  # intenta apagar y encuentra "an idle instance" = ya estaba cerrada.
  # (Son las lineas ORA-01034 / TNS-12541 que se ven al final del log.)
  if ! docker logs --tail 80 "$CONT" 2>&1 | grep -qE "Connected to an idle instance|ORACLE instance shut down"; then
    echo "ERROR: no consta un SHUTDOWN IMMEDIATE limpio en $CONT. Corre el build completo."
    exit 1
  fi
  echo "Contenedor detenido, verificado ($(cat "$MARCA")) y apagado limpio."
else

banner "1/6 — Preparando ($IMAGE)"
if [ "$MEM_LIMIT" = "0" ]; then
  echo "Memoria del contenedor: sin limite"
else
  echo "Memoria del contenedor: $MEM_LIMIT (con swap: $MEMSWAP_LIMIT)"
fi
if [ "$ORDS" = "si" ]; then
  if ! docker image inspect local/oracle19c-se2-ords:19.3.0 >/dev/null 2>&1; then
    echo "ERROR: falta la imagen local/oracle19c-se2-ords:19.3.0"
    echo "Corre primero:  bash ords/descargar.sh && bash ords/construir_base.sh"
    exit 1
  fi
  if [ "$WITH_APEX" = "true" ] && [ ! -f ords/downloads/apex/apxrtins.sql ]; then
    echo "ERROR: falta APEX en ords/downloads/apex/. Corre: bash ords/descargar.sh"
    exit 1
  fi
fi
# Partir siempre de cero: si quedo un contenedor de un intento anterior,
# la base ya existiria y Oracle NO volveria a ejecutar el setup.
limpiar
mkdir -p "$LOGDIR" "$DIST"
# En Linux el contenedor escribe como 'oracle' (uid 54321), no como quien
# corre build.sh. Sin esto install.sh cae a /tmp: el paso 3 no ve
# INSTALL_OK y los logs quedarian horneados en la imagen.
chmod a+rwx "$LOGDIR"
rm -f "$LOGDIR"/*.log "$LOGDIR"/INSTALL_OK "$LOGDIR"/INSTALL_FALLO \
      "$LOGDIR"/ORDS_INSTALL_OK "$LOGDIR"/ORDS_INSTALL_FALLO \
      "$LOGDIR"/ORDS_OK "$LOGDIR"/ORDS_FALLO "$LOGDIR"/respuesta_*.txt

banner "2/6 — Creando la base e instalando (30-55 min segun la variante)"
# El compose de build NO monta volumen en /opt/oracle/oradata: los
# datafiles tienen que quedar en la capa del contenedor para que
# docker commit los capture.
docker compose -p "$PROJ" -f "$COMPOSE" up -d

echo "Esperando a que Oracle termine (crear base + instalar)..."
# El banner aparece DESPUES de que corren los scripts de setup, asi que
# es la senal de que la instalacion ya termino.
while ! docker logs "$CONT" 2>&1 | grep -q "DATABASE IS READY TO USE"; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONT}$"; then
    echo "ERROR: el contenedor se detuvo. Ultimas lineas:"
    docker logs --tail 40 "$CONT" 2>&1
    if [ "$(docker inspect -f '{{.State.OOMKilled}}' "$CONT" 2>/dev/null)" = "true" ]; then
      echo "Lo mato el limite de memoria (MEM_LIMIT=$MEM_LIMIT)."
    fi
    exit 1
  fi
  sleep 30
done
echo "Base lista."

banner "3/6 — Verificando antes de congelar"
# No tiene sentido publicar una imagen rota. Si esto falla, se aborta y
# el contenedor queda vivo para poder revisar los logs.
if [ ! -f "$LOGDIR/INSTALL_OK" ]; then
  echo "ERROR: la instalacion no termino OK."
  [ -f "$LOGDIR/INSTALL_FALLO" ] && cat "$LOGDIR/INSTALL_FALLO"
  echo "El contenedor $CONT sigue en pie para que puedas revisar:"
  echo "  cat $LOGDIR/validate_generalidades.log"
  exit 1
fi
cat "$LOGDIR/INSTALL_OK"

if [ "$ORDS" = "si" ]; then
  if [ ! -f "$LOGDIR/ORDS_INSTALL_OK" ]; then
    echo "ERROR: ORDS no quedo instalado en la base."
    [ -f "$LOGDIR/ORDS_INSTALL_FALLO" ] && cat "$LOGDIR/ORDS_INSTALL_FALLO"
    echo "Revisar: $LOGDIR/ords_install.log  $LOGDIR/validate_ords.log  $LOGDIR/apex_install.log"
    exit 1
  fi
  cat "$LOGDIR/ORDS_INSTALL_OK"

  # 50_ords.sh ya lanzo ORDS despues del banner: es el mismo camino que
  # va a recorrer el contenedor en la maquina de cada persona, asi que
  # se prueba ese y no uno armado para el build.
  echo "Esperando a que ORDS responda..."
  CUERPO_OK=""
  for _ in $(seq 1 60); do
    R=$(http_get /ords/app_demo/v1/prueba || true)
    if [ "$(echo "$R" | http_codigo)" = "200" ]; then CUERPO_OK="$R"; break; fi
    sleep 5
  done
  if [ -z "$CUERPO_OK" ]; then
    echo "ERROR: ORDS no respondio 200 en 5 minutos."
    echo "ords.log:  docker exec $CONT tail -60 /opt/oracle/ords/logs/ords.log"
    echo "sin_respuesta" > "$LOGDIR/ORDS_FALLO"
    exit 1
  fi
  echo "$CUERPO_OK" > "$LOGDIR/respuesta_prueba.txt"
  PLANO=$(echo "$CUERPO_OK" | tr -d '[:space:]')
  if ! echo "$PLANO" | grep -q '"comunas":349' || ! echo "$PLANO" | grep -q '"personas":1000'; then
    echo "ERROR: /prueba respondio pero no con 349 comunas y 1000 personas:"
    echo "$CUERPO_OK"
    echo "prueba_datos_incorrectos" > "$LOGDIR/ORDS_FALLO"
    exit 1
  fi
  echo "GET /ords/app_demo/v1/prueba        -> 200, 349 comunas, 1000 personas"

  # La prueba que distingue a las dos variantes. Mismo endpoint, mismo
  # codigo; lo unico distinto es si APEX esta en la base.
  RA=$(http_get /ords/app_demo/v1/prueba-apex || true)
  echo "$RA" > "$LOGDIR/respuesta_prueba_apex.txt"
  COD_A=$(echo "$RA" | http_codigo)
  if [ "$WITH_APEX" = "true" ]; then
    # Con APEX tiene que funcionar.
    if [ "$COD_A" = "200" ] && echo "$RA" | tr -d '[:space:]' | grep -q '"comunas":349'; then
      echo "GET /ords/app_demo/v1/prueba-apex   -> 200 (apex_json disponible)"
      RESULTADO_APEX="prueba-apex=200"
    else
      echo "ERROR: con APEX instalado, /prueba-apex deberia responder 200. Respondio $COD_A:"
      echo "$RA" | head -40
      echo "prueba_apex=$COD_A" > "$LOGDIR/ORDS_FALLO"
      exit 1
    fi
  else
    # Sin APEX tiene que FALLAR, y por la razon correcta. Si aca
    # respondiera 200, la premisa de esta imagen seria falsa y no hay
    # que repartirla. Se busca el PLS-00201 en la respuesta y, por si
    # ORDS no lo mostrara, tambien en su log.
    EN_LOG=$(docker exec "$CONT" grep -c "PLS-00201" /opt/oracle/ords/logs/ords.log 2>/dev/null || true)
    if [ "$COD_A" != "200" ] && { echo "$RA" | grep -q "PLS-00201" || [ "${EN_LOG:-0}" != "0" ]; }; then
      echo "GET /ords/app_demo/v1/prueba-apex   -> $COD_A con PLS-00201 (APEX_JSON no existe), como se esperaba"
      echo "$RA" | grep -o "PLS-00201: identifier '[^']*' must be declared" | head -1 | sed 's/^/    /'
      RESULTADO_APEX="prueba-apex=${COD_A}+PLS-00201"
    else
      echo "ERROR: sin APEX, /prueba-apex deberia fallar con PLS-00201. Respondio $COD_A:"
      echo "$RA" | head -40
      echo "prueba_apex=$COD_A sin PLS-00201" > "$LOGDIR/ORDS_FALLO"
      exit 1
    fi
  fi
  echo "$(cat "$LOGDIR/ORDS_INSTALL_OK") prueba=200 $RESULTADO_APEX" > "$LOGDIR/ORDS_OK"
  echo "Respuestas guardadas en $LOGDIR/respuesta_*.txt"
fi
echo "Verificacion OK."

banner "4/6 — Apagando limpiamente"
if [ "$ORDS" = "si" ]; then
  # ORDS primero, y el pidfile y el log FUERA: viven en la capa del
  # contenedor, asi que docker commit los hornearia. Con un pidfile
  # viejo en la imagen, 50_ords.sh podria creer que ORDS ya corre y no
  # levantarlo nunca en la maquina de otro.
  docker exec "$CONT" bash -lc '
    bash /opt/oracle/ords/bin/stop_ords.sh
    rm -f /opt/oracle/ords/logs/ords.pid /opt/oracle/ords/logs/*.log
  '
fi
# CRITICO. Un 'docker stop' a secas deja los datafiles a medio escribir
# y la imagen quedaria con una base que necesita recuperacion de
# instancia, o directamente corrupta.
docker exec "$CONT" bash -lc '
  export ORACLE_SID=DEMOCDB
  sqlplus -S "/ as sysdba" <<SQL
SHUTDOWN IMMEDIATE
EXIT
SQL
  lsnrctl stop || true
'
docker stop "$CONT"

fi   # fin de los pasos 1-4 (se saltan con --reanudar)

banner "5/6 — Congelando la imagen"
# Los bind mounts (setup/, logs/, autorun/, apex/) NO se commitean, asi
# que la imagen queda con Oracle + la base (+ ORDS) y nada mas. Por eso
# el repo que se comparte no necesita ningun script.
docker commit --message "${DESC} (v${VERSION})" "$CONT" "$IMAGE"

docker images "$IMAGE" --format "  {{.Repository}}:{{.Tag}}  {{.Size}}"

banner "6/6 — Empaquetando para repartir"
OUT="${DIST}/${NOMBRE}-${VERSION}.tar.gz"
echo "Generando $OUT (tarda unos minutos)..."
docker save "$IMAGE" | gzip > "$OUT"
ls -lh "$OUT"

banner "LISTO"
cat <<FIN
Imagen:  $IMAGE
Archivo: $OUT

Para repartir:
  1. Copia $OUT al servidor o carpeta compartida.
  2. Avisa la version y actualiza CHANGELOG.md.

Quien la reciba:
  docker load -i ${NOMBRE}-${VERSION}.tar.gz
  docker compose up -d
FIN

# El contenedor de construccion ya no sirve para nada.
docker rm "$CONT" >/dev/null 2>&1 || true
