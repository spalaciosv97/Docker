#!/usr/bin/env bash
# =====================================================================
# install_ords.sh — ORDS (y APEX runtime, si WITH_APEX=true) en DEMOPDB
#
# Lo ejecuta Oracle solo, despues de install.sh, via
# autorun-ords/01_install.sh. Tambien se puede reiterar a mano:
#   docker exec -it oracle19-build-ords bash /poc/install_ords.sh
# (es idempotente: salta lo que ya este instalado).
#
# Pasos:
#   1/4  APEX runtime           solo con WITH_APEX=true
#   2/4  ords install           crea ORDS_METADATA y ORDS_PUBLIC_USER
#   3/4  ords config            puerto, pool chico, errores visibles
#   4/4  REST en APP_DEMO       los dos endpoints de prueba
#
# Aca se valida lo que se le puede preguntar a la BASE. La prueba HTTP
# (que ORDS responda y que /prueba-apex falle o no segun la variante)
# la hace build.sh, contra el ORDS ya levantado por 50_ords.sh, que es
# el mismo camino que va a recorrer el contenedor en la maquina de
# cualquier persona.
# =====================================================================

set -uo pipefail
export NLS_LANG=.AL32UTF8

export JAVA_HOME=/opt/java/jre21
export PATH="$JAVA_HOME/bin:/opt/oracle/ords/product/bin:$PATH"
ORDS_CFG=/opt/oracle/ords/config

SETUP=/poc/setup
LOGS=/poc/logs
cd "$LOGS" || exit 1
rm -f "$LOGS/ORDS_INSTALL_OK" "$LOGS/ORDS_INSTALL_FALLO"

WITH_APEX="${WITH_APEX:-false}"
ORACLE_PWD="${ORACLE_PWD:-Oracle_Poc_2026}"
APP_DEMO_PWD="${APP_DEMO_PWD:-App_Demo_2026}"
ORDS_PUBLIC_PWD="${ORDS_PUBLIC_PWD:-Ords_Pub_2026}"

SYS_CONN="sys/${ORACLE_PWD}@localhost:1521/DEMOCDB as sysdba"
# APEX se instala conectado DIRECTO al PDB, no con ALTER SESSION SET
# CONTAINER: su instalador abre sesiones propias y tiene que caer en el
# mismo contenedor.
PDB_SYS_CONN="sys/${ORACLE_PWD}@localhost:1521/DEMOPDB as sysdba"
APP_CONN="APP_DEMO/${APP_DEMO_PWD}@localhost:1521/DEMOPDB"

banner() {
  echo
  echo "====================================================================="
  echo "  $1"
  echo "====================================================================="
}

# Devuelve un valor escalar de la base, sin espacios. Si la consulta
# falla devuelve VACIO, no el texto del error: sin esto, un ORA-06598
# pasaba por "version de ORDS" y el veredicto lo daba por bueno.
sql_valor() {
  local r
  r=$(sqlplus -S "$SYS_CONN" <<EOF | tr -d '[:space:]'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
ALTER SESSION SET CONTAINER = DEMOPDB;
$1
EXIT
EOF
)
  case "$r" in *ORA-*|*ERROR*|*SP2-*) echo "" ;; *) echo "$r" ;; esac
}

echo "Variante: WITH_APEX=${WITH_APEX}"

banner "PASO 1/4 — APEX runtime"
if [ "$WITH_APEX" != "true" ]; then
  echo "Variante SIN APEX — se salta. A proposito: esta imagen existe para"
  echo "mostrar que ORDS por si solo NO trae APEX_JSON."
elif [ "$(sql_valor "SELECT COUNT(*) FROM dba_registry WHERE comp_id='APEX';")" = "1" ]; then
  echo "APEX ya esta instalado — se salta."
else
  if [ ! -f /poc/apex/apxrtins.sql ]; then
    echo "ERROR: no esta /poc/apex/apxrtins.sql. Corre ords/descargar.sh."
    echo "falta_apex" > "$LOGS/ORDS_INSTALL_FALLO"
    exit 1
  fi
  # El instalador de APEX escribe sus logs en el directorio actual, y
  # /poc/apex es de solo lectura. Se copia a /tmp y se borra al final:
  # si quedara, docker commit lo hornearia (~1 GB de basura).
  rm -rf /tmp/apex && cp -r /poc/apex /tmp/apex
  (
    cd /tmp/apex || exit 1
    # "Runtime": solo los packages (APEX_JSON, APEX_UTIL, ...), sin el
    # entorno de desarrollo web. Es lo que necesitan los handlers.
    #   apxrtins.sql <tablespace APEX> <tablespace archivos> <temp> <imagenes>
    sqlplus -S "$PDB_SYS_CONN" <<'EOF'
WHENEVER SQLERROR CONTINUE
CREATE TABLESPACE APEX DATAFILE SIZE 300M AUTOEXTEND ON NEXT 50M MAXSIZE 4G;
@apxrtins.sql APEX APEX TEMP /i/
EXIT
EOF
  ) > "$LOGS/apex_install.log" 2>&1
  cp /tmp/apex/*.log "$LOGS/" 2>/dev/null || true
  rm -rf /tmp/apex
  echo "APEX: $(sql_valor "SELECT version||' '||status FROM dba_registry WHERE comp_id='APEX';")"
fi

banner "PASO 2/4 — ords install (ORDS_METADATA + ORDS_PUBLIC_USER)"
if [ "$(sql_valor "SELECT COUNT(*) FROM dba_users WHERE username='ORDS_METADATA';")" = "1" ]; then
  echo "ORDS_METADATA ya existe — se salta."
else
  # --password-stdin lee DOS lineas: la del admin (SYS) y la que tendra
  # ORDS_PUBLIC_USER, el usuario del pool. Es la unica forma de que no
  # pregunte nada. En ORDS 26 la segunda linea solo se lee si ademas va
  # --proxy-user; sin esa bandera falla con "The ORDS_PUBLIC_USER
  # password must be provided for non-interactive install".
  #
  # timeout: si a 'ords install' le faltara un dato se pondria a esperar
  # respuesta por teclado, y el build quedaria colgado sin decir nada.
  # Asi falla a los 15 minutos y con motivo.
  #
  # --gateway-mode disabled en las DOS variantes, tambien en la con
  # APEX: el gateway es para servir aplicaciones APEX, que no se usan.
  # Asi la unica diferencia entre ambas imagenes es APEX en la base.
  printf '%s\n%s\n' "$ORACLE_PWD" "$ORDS_PUBLIC_PWD" | \
    timeout 900 ords --config "$ORDS_CFG" install \
      --admin-user               "SYS AS SYSDBA" \
      --db-hostname              localhost \
      --db-port                  1521 \
      --db-servicename           DEMOPDB \
      --feature-sdw              true \
      --feature-db-api           true \
      --feature-rest-enabled-sql true \
      --gateway-mode             disabled \
      --log-folder               "$LOGS" \
      --proxy-user \
      --password-stdin > "$LOGS/ords_install.log" 2>&1
  echo "ords install: codigo de salida $? (detalle en ords_install.log)"
fi

banner "PASO 3/4 — Configuracion de ORDS"
# El pool apunta a localhost:1521 DENTRO del contenedor, asi que no
# depende del puerto que cada persona publique en su maquina.
ords --config "$ORDS_CFG" config set standalone.http.port 8080
# Pool chico: esto corre en un notebook, al lado de Oracle. Sin
# --db-pool: ORDS 26 rechaza "--db-pool default" (el pool default es
# implicito) y estos valores caen justamente en ese pool.
ords --config "$ORDS_CFG" config set jdbc.InitialLimit 2
ords --config "$ORDS_CFG" config set jdbc.MinLimit 2
ords --config "$ORDS_CFG" config set jdbc.MaxLimit 10
# Que el error de un handler se vea en la respuesta HTTP y no solo en
# el log del servidor. Es un entorno de desarrollo: quien escribe un
# endpoint necesita ver el PLS-00201 en el navegador.
ords --config "$ORDS_CFG" config set debug.printDebugToScreen true

banner "PASO 4/4 — REST en APP_DEMO"
sqlplus -S "$APP_CONN" @"${SETUP}/60_ords/10_rest_app_demo.sql"

banner "VALIDACION"
sqlplus -S "$SYS_CONN" @"${SETUP}/60_ords/99_validate_ords.sql" > /dev/null
cat "$LOGS/validate_ords.log"

VERSION_ORDS=$(sql_valor "SELECT MAX(version) FROM ords_metadata.ords_version;")
INVAL=$(sql_valor "SELECT COUNT(*) FROM dba_objects WHERE (owner='ORDS_METADATA' OR owner LIKE 'APEX\_%' ESCAPE '\\' OR owner='FLOWS_FILES') AND status<>'VALID';")
REST=$(sql_valor "SELECT COUNT(*) FROM ords_metadata.ords_schemas WHERE parsing_schema='APP_DEMO' AND status='ENABLED';")
HANDLERS=$(sql_valor "SELECT COUNT(*) FROM ords_metadata.ords_modules m JOIN ords_metadata.ords_templates t ON t.module_id=m.id JOIN ords_metadata.ords_handlers h ON h.template_id=t.id WHERE m.name='demo.v1';")
APEX=$(sql_valor "SELECT COUNT(*) FROM dba_registry WHERE comp_id='APEX' AND status='VALID';")
VERSION_APEX=$(sql_valor "SELECT NVL(MAX(version),'-') FROM dba_registry WHERE comp_id='APEX';")

if [ "$WITH_APEX" = "true" ]; then APEX_ESPERADO=1; else APEX_ESPERADO=0; fi

banner "VEREDICTO"
echo "Version de ORDS        : ${VERSION_ORDS:-(vacia)}"
echo "Objetos invalidos      : $INVAL   (debe ser 0)"
echo "APP_DEMO con REST      : $REST   (debe ser 1)"
echo "Endpoints demo.v1      : $HANDLERS   (debe ser 2)"
echo "APEX instalado y VALID : $APEX   (debe ser $APEX_ESPERADO)   version $VERSION_APEX"
echo "Config del pool        : $([ -f "$ORDS_CFG/databases/default/pool.xml" ] && echo presente || echo FALTA)"

RESUMEN="ords=$VERSION_ORDS apex=$VERSION_APEX invalidos=$INVAL rest=$REST handlers=$HANDLERS"
if [ -n "$VERSION_ORDS" ] && [ "$INVAL" = "0" ] && [ "$REST" = "1" ] \
   && [ "$HANDLERS" = "2" ] && [ "$APEX" = "$APEX_ESPERADO" ] \
   && [ -f "$ORDS_CFG/databases/default/pool.xml" ]; then
  echo "$RESUMEN" > "$LOGS/ORDS_INSTALL_OK"
  echo
  echo "ORDS INSTALADO. La prueba HTTP la hace build.sh."
  exit 0
else
  echo "$RESUMEN apex_esperado=$APEX_ESPERADO" > "$LOGS/ORDS_INSTALL_FALLO"
  echo
  echo "FALLO. Ver ords_install.log, validate_ords.log y apex_install.log."
  exit 1
fi
