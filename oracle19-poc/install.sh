#!/usr/bin/env bash
# =====================================================================
# install.sh — Instala GENERALIDADES en DEMOPDB
#
# Lo ejecuta Oracle solo, la primera vez que crea la base, via
# autorun/01_install.sh montado en /opt/oracle/scripts/setup.
#
# Tambien se puede correr a mano para iterar:
#   docker exec -it oracle19-build bash /poc/install.sh
#
# Si falla a mitad, la base ya existe y Oracle NO vuelve a ejecutar el
# setup. Hay que destruir el volumen (o el contenedor, al construir) y
# empezar de nuevo.
# =====================================================================

set -uo pipefail

# --- NLS_LANG es critico ---------------------------------------------
# Los .sql estan en UTF-8 y la base es AL32UTF8. Sin esto, sqlplus asume
# el charset del SO (US7ASCII) y los acentos entran corruptos a la base
# de forma permanente.
export NLS_LANG=.AL32UTF8

SETUP=/poc/setup

# --- Logs con respaldo -----------------------------------------------
# Desatendido no hay quien diagnostique un directorio sin permisos, asi
# que si /poc/logs no se puede escribir, se cae a /tmp y se avisa.
LOGS=/poc/logs
if ! mkdir -p "$LOGS" 2>/dev/null || ! touch "$LOGS/.w" 2>/dev/null; then
  LOGS=/tmp/poc-logs
  mkdir -p "$LOGS"
  echo "AVISO: /poc/logs no es escribible. Los logs van a $LOGS"
fi
rm -f "$LOGS/.w" "$LOGS/INSTALL_OK" "$LOGS/INSTALL_FALLO"
cd "$LOGS" || exit 1

# --- Credenciales ----------------------------------------------------
# Vienen del .env via compose; los defaults permiten correr el script
# suelto. Son de una base local descartable, sin datos reales.
ORACLE_PWD="${ORACLE_PWD:-Oracle_Poc_2026}"
GRL_PWD="${GRL_PWD:-Grl_Poc_2026}"
AUDITOR_PWD="${AUDITOR_PWD:-Aud_Poc_2026}"
SIGE_PWD="${SIGE_PWD:-Sig_Poc_2026}"
STUB_PWD="${STUB_PWD:-Stub_Poc_2026}"
APP_DEMO_PWD="${APP_DEMO_PWD:-App_Demo_2026}"

SYS_CONN="sys/${ORACLE_PWD}@localhost:1521/DEMOCDB as sysdba"
GRL_CONN="GENERALIDADES/${GRL_PWD}@localhost:1521/DEMOPDB"

banner() {
  echo
  echo "====================================================================="
  echo "  $1"
  echo "====================================================================="
}

run_sys() {
  sqlplus -S "$SYS_CONN" @"$1"
}

banner "PASO 1/8 — Pre-requisitos (tablespaces, esquemas, usuario)"
# Se salta si ya existe GENERALIDADES: los CREATE USER / CREATE
# TABLESPACE no son reejecutables y llenarian el log de ORA-01920 y
# ORA-01543 que no aportan nada.
YA=$(sqlplus -S "$SYS_CONN" <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
ALTER SESSION SET CONTAINER = DEMOPDB;
SELECT COUNT(*) FROM dba_users WHERE username = 'GENERALIDADES';
EXIT
EOF
)
if echo "$YA" | grep -q '1'; then
  echo "GENERALIDADES ya existe — se salta el paso 1."
else
  # ORDEN IMPORTANTE: GENERALIDADES va SEGUNDO, antes que AUDITOR y
  # SIGESUSTIC, porque esos dos le hacen GRANT. Al reves, los GRANT
  # fallan con ORA-01917 y PKG_LOG queda INVALID (usa %TYPE contra
  # AUDITOR.LOG_SYSTEM), arrastrando a los 20 bodies que dependen de el.
  for s in 01_tablespaces 02_generalidades_user 03_roles_stub 04_auditor_min 05_sigesustic_min; do
    echo "--- $s"
    # Los DEFINE van DESPUES de 00_env.sql: ese archivo trae los valores
    # de respaldo, y estos los pisan con lo que venga del .env. Al reves,
    # 00_env sobrescribiria lo inyectado.
    sqlplus -S "$SYS_CONN" <<EOF
@${SETUP}/01_pre/00_env.sql
DEFINE GRL_PWD = ${GRL_PWD}
DEFINE AUDITOR_PWD = ${AUDITOR_PWD}
DEFINE SIGE_PWD = ${SIGE_PWD}
DEFINE STUB_PWD = ${STUB_PWD}
@${SETUP}/01_pre/${s}.sql
EXIT
EOF
  done
fi

banner "PASO 2/8 — GENERALIDADES (DDL + packages)"
# Hay que ejecutarlo con el directorio actual EN la carpeta del MASTER.
# Invocarlo por ruta absoluta no sirve: SQL*Plus resuelve las 80
# referencias @@ contra el directorio de trabajo, no contra el del
# script, y todas fallan con SP2-0310.
( cd "${SETUP}/10_generalidades" && sqlplus -S "$GRL_CONN" @MASTER_GRL_DOCKER.sql )

banner "PASO 3/8 — Datos maestros (referencias, comunas, parametros)"
# Orden obligatorio por FK: referencia -> item -> parametro.
# GRL_PARAMETRO dispara TRG_VALIDA_GRL_PARAMETRO_FK, que valida contra
# SIGESUSTIC; las semillas de 05_sigesustic_min.sql cubren esos IDs.
sqlplus -S "$GRL_CONN" <<EOF
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE
SPOOL ${LOGS}/load_data.log
@${SETUP}/30_data/01_GRL_REFERENCIA.sql
@${SETUP}/30_data/02_GRL_REFERENCIA_ITEM.sql
@${SETUP}/30_data/03_GRL_PARAMETRO.sql
COMMIT;
SPOOL OFF
EXIT
EOF

banner "PASO 4/8 — Fixture: 1000 personas sinteticas"
# Datos generados, NO extraidos de Desarrollo. Ver el encabezado de
# personas.sql. Va despues del paso 3 porque necesita las referencias
# y las 349 comunas.
sqlplus -S "$GRL_CONN" @"${SETUP}/35_fixtures/personas.sql"

banner "PASO 5/8 — Sinonimos publicos (como SYS)"
run_sys "${SETUP}/20_post/sinonimos_publicos.sql"

banner "PASO 6/8 — Recompilacion final"
# Imprescindible: varios bodies llaman a los packages por sus sinonimos
# publicos (CONST, UTILIDADES, VALIDATOR), que recien existen despues
# del paso 5. Sin esta pasada quedan 19 bodies INVALID.
run_sys "${SETUP}/40_recompile/recompile.sql"

banner "PASO 7/8 — Esquema de ejemplo APP_DEMO"
# Se instala con la imagen para que el desarrollador encuentre un
# ejemplo funcionando de como consumir GENERALIDADES desde su esquema.
sqlplus -S "$SYS_CONN" <<EOF
DEFINE APP_DEMO_PWD = ${APP_DEMO_PWD}
@${SETUP}/50_app_demo/app_demo.sql
EXIT
EOF

banner "PASO 8/8 — Validacion"
run_sys "${SETUP}/99_validation/validate_generalidades.sql"

banner "RESUMEN DE ERRORES EN LOS LOGS"
for f in "$LOGS"/*.log; do
  [ -f "$f" ] || continue
  n=$(grep -c '^ORA-' "$f" 2>/dev/null || echo 0)
  echo "  $(basename "$f"): $n"
done
echo
echo "Errores distintos:"
grep -h '^ORA-' "$LOGS"/*.log 2>/dev/null \
  | sed 's/:.*//' | sort | uniq -c | sort -rn || echo "  (ninguno)"

banner "VEREDICTO"
# Contar ORA- en los logs NO alcanza como criterio: un package body que
# no compila queda INVALID sin emitir ninguna linea ORA- en el spool.
# El criterio real se le pregunta a la base.
RES=$(sqlplus -S "$SYS_CONN" <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
ALTER SESSION SET CONTAINER = DEMOPDB;
SELECT (SELECT COUNT(*) FROM dba_objects
         WHERE owner IN ('GENERALIDADES','APP_DEMO') AND status <> 'VALID')
       || '|' ||
       (SELECT COUNT(*) FROM GENERALIDADES.GRL_PERSONA)
  FROM dual;
EXIT
EOF
)
RES=$(echo "$RES" | tr -d '[:space:]')
INVAL="${RES%%|*}"
PERS="${RES##*|}"

echo "Objetos invalidos : $INVAL   (debe ser 0)"
echo "Personas cargadas : $PERS   (debe ser 1000)"

if [ "$INVAL" = "0" ] && [ "$PERS" = "1000" ]; then
  echo "OK" > "$LOGS/INSTALL_OK"
  echo
  echo "INSTALACION CORRECTA."
  exit 0
else
  echo "invalidos=$INVAL personas=$PERS" > "$LOGS/INSTALL_FALLO"
  echo
  echo "FALLO. Ver la seccion 4 de validate_generalidades.log."
  exit 1
fi
