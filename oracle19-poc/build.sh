#!/usr/bin/env bash
# =====================================================================
# build.sh — Construye la imagen distribuible con la base ya instalada
#
#   ./build.sh 1.0.0
#
# Produce:
#   - imagen  oracle19c-grl:<version>
#   - archivo dist/oracle19c-grl-<version>.tar.gz   (para repartir)
#
# Tarda ~30 min: Oracle crea la base (~25) y despues corre la
# instalacion (~3). Es el precio de que despues arranque en 1-3 min en
# la maquina de cada persona.
#
# Se corre desde WSL/Git Bash en la carpeta oracle19-poc/.
# =====================================================================

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Uso: ./build.sh <version>    (ej: ./build.sh 1.0.0)"
  exit 1
fi

IMAGE="oracle19c-grl:${VERSION}"
PROJ="oracle19-build"
CONT="oracle19-build"
DIST="dist"

banner() {
  echo
  echo "====================================================================="
  echo "  $1"
  echo "====================================================================="
}

limpiar() {
  docker compose -p "$PROJ" -f compose.build.yaml down 2>/dev/null || true
}

banner "1/6 — Preparando"
# Partir siempre de cero: si quedo un contenedor de un intento anterior,
# la base ya existiria y Oracle NO volveria a ejecutar el setup.
limpiar
rm -f logs/*.log logs/INSTALL_OK logs/INSTALL_FALLO
mkdir -p "$DIST"

banner "2/6 — Creando la base e instalando (esto tarda ~30 min)"
# compose.build.yaml NO monta volumen en /opt/oracle/oradata: los
# datafiles tienen que quedar en la capa del contenedor para que
# docker commit los capture.
docker compose -p "$PROJ" -f compose.build.yaml up -d

echo "Esperando a que Oracle termine (crear base + instalar)..."
# El banner aparece DESPUES de que corren los scripts de setup, asi que
# es la senal de que la instalacion ya termino.
while ! docker logs "$CONT" 2>&1 | grep -q "DATABASE IS READY TO USE"; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONT}$"; then
    echo "ERROR: el contenedor se detuvo. Ultimas lineas:"
    docker logs --tail 40 "$CONT" 2>&1
    exit 1
  fi
  sleep 30
done
echo "Base lista."

banner "3/6 — Verificando antes de congelar"
# No tiene sentido publicar una imagen rota. Si esto falla, se aborta y
# el contenedor queda vivo para poder revisar los logs.
if [ ! -f logs/INSTALL_OK ]; then
  echo "ERROR: la instalacion no termino OK."
  [ -f logs/INSTALL_FALLO ] && cat logs/INSTALL_FALLO
  echo "El contenedor $CONT sigue en pie para que puedas revisar:"
  echo "  cat logs/validate_generalidades.log"
  exit 1
fi
cat logs/INSTALL_OK
echo "Verificacion OK."

banner "4/6 — Apagando Oracle limpiamente"
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

banner "5/6 — Congelando la imagen"
# Los bind mounts (setup/, logs/, autorun/) NO se commitean, asi que la
# imagen queda con Oracle + la base y nada mas. Por eso el repo que se
# comparte no necesita ningun script.
docker commit \
  --message "Oracle 19c SE2 + GENERALIDADES + fixture 1000 personas (v${VERSION})" \
  "$CONT" "$IMAGE"

docker images "$IMAGE" --format "  {{.Repository}}:{{.Tag}}  {{.Size}}"

banner "6/6 — Empaquetando para repartir"
OUT="${DIST}/oracle19c-grl-${VERSION}.tar.gz"
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
  gunzip -c oracle19c-grl-${VERSION}.tar.gz | docker load
  docker compose up -d
FIN

# El contenedor de construccion ya no sirve para nada.
docker rm "$CONT" >/dev/null 2>&1 || true
