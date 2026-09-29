#!/usr/bin/env bash
# =====================================================================
# construir_base.sh — Construye local/oracle19c-se2-ords:19.3.0
#
#   bash ords/construir_base.sh
#
# Requiere haber corrido antes ords/descargar.sh. Tarda 1-2 minutos.
# Se corre una vez; despues build.sh --ords / --ords-apex la reutilizan.
# =====================================================================

set -euo pipefail
cd "$(dirname "$0")"

BASE_ORDS="local/oracle19c-se2-ords:19.3.0"

for d in downloads/jre/bin/java downloads/ords/bin/ords; do
  if [ ! -e "$d" ]; then
    echo "ERROR: falta $d. Corre primero: bash ords/descargar.sh"
    exit 1
  fi
done

docker build -t "$BASE_ORDS" .

# Prueba de humo ANTES de gastar una hora en un build completo: si Java
# no corre sobre Oracle Linux 7, se sabe aca y no a los 50 minutos.
echo
echo "--- Prueba de humo"
docker run --rm --entrypoint bash "$BASE_ORDS" -lc '
  java -version 2>&1 | head -1
  ords --version 2>&1 | grep -i "ords\|version" | head -2
  ls -l /opt/oracle/scripts/startup/
'
echo
echo "Listo: $BASE_ORDS"
