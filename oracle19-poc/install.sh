#!/usr/bin/env bash
# =====================================================================
# install.sh — Instala GENERALIDADES en DEMOPDB
#
# Se ejecuta DENTRO del contenedor:
#
#   docker exec -it oracle19-lab bash /poc/install.sh
#
# Es idempotente solo hasta cierto punto: si falla a mitad, lo mas
# limpio es destruir el volumen del LAB y volver a empezar (ver
# compose.lab.yaml). Por eso la primera pasada va contra el lab
# descartable y no contra la base que ya funciona.
#
# Los logs quedan en /poc/logs (montado desde el host).
# =====================================================================

set -uo pipefail

# --- NLS_LANG es critico ---------------------------------------------
# Los .sql estan en UTF-8 y la base es AL32UTF8. Sin esto, sqlplus
# asume el charset del SO (US7ASCII en la imagen) y los acentos entran
# corruptos a la base de forma permanente.
export NLS_LANG=.AL32UTF8

SETUP=/poc/setup
LOGS=/poc/logs
mkdir -p "$LOGS"
cd "$LOGS" || exit 1

SYS_CONN='sys/Oracle_Poc_2026@localhost:1521/DEMOCDB as sysdba'
GRL_CONN='GENERALIDADES/Grl_Poc_2026@localhost:1521/DEMOPDB'

banner() {
  echo
  echo "====================================================================="
  echo "  $1"
  echo "====================================================================="
}

# sqlplus devuelve 0 aunque haya errores ORA-, porque los scripts usan
# WHENEVER SQLERROR CONTINUE a proposito (queremos ver TODOS los fallos
# de una pasada, no parar en el primero). Por eso al final se cuentan
# los ORA- en los logs en vez de confiar en el exit code.
run_sys() {
  sqlplus -S "$SYS_CONN" @"$1"
}

banner "PASO 1/5 — Pre-requisitos (tablespaces, esquemas, usuario)"
# Se salta si ya existe GENERALIDADES: los CREATE USER / CREATE
# TABLESPACE no son reejecutables y llenarian el log de ORA-01920 y
# ORA-01543 que no aportan nada. Para rehacerlo desde cero, destruir el
# volumen del lab (ver compose.lab.yaml).
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
  # 00_env.sql define las variables y hace ALTER SESSION SET CONTAINER,
  # por eso cada script se concatena con el en una sola sesion.
  # ORDEN IMPORTANTE: GENERALIDADES va SEGUNDO, antes que AUDITOR y
  # SIGESUSTIC, porque esos dos le hacen GRANT. Al reves, los GRANT
  # fallan con ORA-01917 y PKG_LOG queda INVALID (usa %TYPE contra
  # AUDITOR.LOG_SYSTEM), arrastrando a los 20 bodies que dependen de el.
  for s in 01_tablespaces 02_generalidades_user 03_roles_stub 04_auditor_min 05_sigesustic_min; do
    echo "--- $s"
    sqlplus -S "$SYS_CONN" <<EOF
@${SETUP}/01_pre/00_env.sql
@${SETUP}/01_pre/${s}.sql
EXIT
EOF
  done
fi

banner "PASO 2/5 — GENERALIDADES (DDL + packages)"
# Hay que ejecutarlo con el directorio actual EN la carpeta del MASTER.
# Invocarlo por ruta absoluta no sirve: SQL*Plus resuelve las 80
# referencias @@ contra el directorio de trabajo, no contra el del
# script, y todas fallan con SP2-0310.
# Por eso el MASTER hace SPOOL a /poc/logs con ruta absoluta: su propia
# carpeta esta montada de solo lectura.
( cd "${SETUP}/10_generalidades" && sqlplus -S "$GRL_CONN" @MASTER_GRL_DOCKER.sql )

banner "PASO 3/5 — Datos maestros"
# Orden obligatorio por FK: referencia -> item -> parametro.
# GRL_PARAMETRO dispara TRG_VALIDA_GRL_PARAMETRO_FK, que valida contra
# SIGESUSTIC; las semillas de 04_sigesustic_min.sql cubren esos IDs.
sqlplus -S "$GRL_CONN" <<EOF
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE
SPOOL load_data.log
@${SETUP}/30_data/01_GRL_REFERENCIA.sql
@${SETUP}/30_data/02_GRL_REFERENCIA_ITEM.sql
@${SETUP}/30_data/03_GRL_PARAMETRO.sql
COMMIT;
SPOOL OFF
EXIT
EOF

banner "PASO 4/6 — Sinonimos publicos (como SYS)"
run_sys "${SETUP}/20_post/sinonimos_publicos.sql"

banner "PASO 5/6 — Recompilacion final"
# Imprescindible: varios bodies llaman a los packages por sus sinonimos
# publicos (CONST, UTILIDADES, VALIDATOR), que recien existen despues
# del paso 4. Sin esta pasada quedan 19 bodies INVALID.
run_sys "${SETUP}/40_recompile/recompile.sql"

banner "PASO 6/6 — Validacion"
run_sys "${SETUP}/99_validation/validate_generalidades.sql"

banner "RESUMEN DE ERRORES EN LOS LOGS"
echo "Logs en $LOGS:"
ls -1 "$LOGS"
echo
echo "Errores ORA- por log (excluyendo los esperados):"
for f in "$LOGS"/*.log; do
  [ -f "$f" ] || continue
  n=$(grep -c '^ORA-' "$f" 2>/dev/null || echo 0)
  echo "  $(basename "$f"): $n"
done
echo
echo "Detalle de errores distintos:"
grep -h '^ORA-' "$LOGS"/*.log 2>/dev/null \
  | sed 's/:.*//' | sort | uniq -c | sort -rn || echo "  (ninguno)"

banner "VEREDICTO"
# Contar ORA- en los logs NO alcanza como criterio: un package body que
# no compila queda INVALID sin emitir ninguna linea ORA- en el spool.
# El criterio real se le pregunta a la base.
INVAL=$(sqlplus -S "$SYS_CONN" <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
ALTER SESSION SET CONTAINER = DEMOPDB;
SELECT COUNT(*) FROM dba_objects
 WHERE owner = 'GENERALIDADES' AND status <> 'VALID';
EXIT
EOF
)
INVAL=$(echo "$INVAL" | tr -d '[:space:]')

if [ "$INVAL" = "0" ]; then
  echo "OK — 0 objetos invalidos en GENERALIDADES."
  echo
  echo "Siguiente paso, la prueba que demuestra la PoC:"
  echo "  docker exec -it oracle19-lab bash -c \\"
  echo "    'NLS_LANG=.AL32UTF8 sqlplus -S \"sys/…@localhost:1521/DEMOCDB as sysdba\" \\"
  echo "     @/poc/setup/99_validation/prueba_funcional.sql'"
  exit 0
else
  echo "FALLO — quedan $INVAL objetos invalidos."
  echo "Ver la seccion 4 de logs/validate_generalidades.log."
  exit 1
fi
