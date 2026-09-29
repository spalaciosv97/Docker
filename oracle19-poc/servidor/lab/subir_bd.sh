#!/usr/bin/env bash
# =====================================================================
# subir_bd.sh — Vuelve a levantar la base del lab (despues de bajar_bd.sh)
#
#   ssh docker-prod bash oracle19-lab-ords/subir_bd.sh
#
# ORDS no se reinicia: se reconecta solo (~1 s despues de abrir la base).
# =====================================================================

set -euo pipefail
docker exec -i oracle19-lab-ords bash -lc 'export ORACLE_SID=DEMOCDB; sqlplus -S "/ as sysdba"' <<SQL
startup
set heading off feedback off
select 'PDB ' || name || ': ' || open_mode from v\$pdbs where name = 'DEMOPDB';
exit
SQL
echo "Base arriba a las $(date +%T)."
