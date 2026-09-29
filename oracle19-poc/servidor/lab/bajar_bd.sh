#!/usr/bin/env bash
# =====================================================================
# bajar_bd.sh — Baja la base del lab; ORDS sigue arriba
#
#   ssh docker-prod bash oracle19-lab-ords/bajar_bd.sh          (ordenada)
#   ssh docker-prod bash oracle19-lab-ords/bajar_bd.sh abort    (brusca)
#
# Para volver: subir_bd.sh. Si el lab tiene healthcheck, autoheal lo
# reinicia a los ~7 min: ver compose.sin-healthcheck.yaml.
# =====================================================================

set -euo pipefail
MODO="${1:-immediate}"
case "$MODO" in immediate|abort) ;; *) echo "Uso: bajar_bd.sh [immediate|abort]"; exit 1 ;; esac

SALUD=$(docker inspect -f '{{if .State.Health}}con healthcheck{{else}}sin healthcheck{{end}}' oracle19-lab-ords)
echo "Lab $SALUD."
[ "$SALUD" = "con healthcheck" ] && echo "AVISO: autoheal lo va a reiniciar si queda abajo ~7 min."

docker exec -i oracle19-lab-ords bash -lc 'export ORACLE_SID=DEMOCDB; sqlplus -S "/ as sysdba"' <<SQL
shutdown $MODO
exit
SQL
echo "Base abajo ($MODO) a las $(date +%T). ORDS sigue corriendo."
