#!/usr/bin/env bash
# =====================================================================
# build_servidor.sh — build.sh, pero como corresponde en docker-prod
#
#   bash servidor/build_servidor.sh 1.1.0 --ords     (en el servidor)
#
# Recibe los mismos argumentos que build.sh y corre EL MISMO build.sh.
# Lo unico que agrega es lo que exige un servidor de produccion
# compartido:
#
#   - MEM_LIMIT=4g: si el build se pasa, muere el build y no el portal
#     de pago (se puede cambiar con MEM_LIMIT=...).
#   - No arranca si el lab (oracle19-lab-*) esta corriendo: los dos no
#     caben en la RAM del servidor.
#   - nohup + setsid: sigue aunque se corte el SSH. Deja el log en
#     logs/build_<version><variante>.log.
#
# Antes, desde el notebook: bash servidor/subir_al_servidor.sh
# =====================================================================

set -euo pipefail
cd "$(dirname "$0")/.."          # oracle19-poc/

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Uso: bash servidor/build_servidor.sh <version> [--ords | --ords-apex] [--reanudar]"
  exit 1
fi
export MEM_LIMIT="${MEM_LIMIT:-4g}"

LAB=$(docker ps --filter name=oracle19-lab --format '{{.Names}}')
if [ -n "$LAB" ]; then
  echo "ERROR: el lab esta corriendo ($LAB) y no caben los dos en RAM."
  echo "Paralo primero (los datos quedan en su volumen):"
  echo "  cd ~/oracle19-lab-ords && docker compose -p oracle19-lab-ords -f compose.yaml -f compose.servidor.yaml stop"
  exit 1
fi
if pgrep -u "$(id -u)" -f "build.sh $VERSION" >/dev/null; then
  echo "ERROR: ya hay un build.sh $VERSION corriendo."
  exit 1
fi

echo "Recursos antes de empezar:"
free -h | head -2
df -h / /home | tail -2
echo "Commit: $(cat COMMIT.txt 2>/dev/null || echo 'desconocido (no se subio con subir_al_servidor.sh)')"

VARIANTE=""
case "${2:-}" in --ords|--ords-apex) VARIANTE="${2#--}" ;; esac
LOG="logs/build_${VERSION}${VARIANTE:+_$VARIANTE}.log"
mkdir -p logs
nohup setsid ./build.sh "$@" > "$LOG" 2>&1 < /dev/null &

echo
echo "Build lanzado con MEM_LIMIT=$MEM_LIMIT (~30-35 min). Se puede cerrar el SSH."
echo "Seguirlo:   tail -f ~/oracle19-poc/$LOG"
echo "Memoria:    docker stats oracle19-build${VARIANTE:+-$VARIANTE}"
