#!/usr/bin/env bash
# =====================================================================
# subir_al_servidor.sh — Deja docker-prod listo para construir
#
#   bash servidor/subir_al_servidor.sh            (desde el notebook)
#
# Se corre en el NOTEBOOK (Git Bash o WSL). Hace tres cosas, y cada una
# solo si hace falta:
#
#   1. Copia el codigo del ultimo commit a ~/oracle19-poc del servidor.
#      No toca dist/, logs/ ni ords/downloads/ de alla.
#   2. Manda la imagen base local/oracle19c-se2:19.3.0 (9,5 GB, ~10 min)
#      en streaming: no ocupa disco del notebook.
#   3. Deja en ords/downloads/ del servidor el Java y el ORDS EXACTOS de
#      la imagen ORDS del notebook (~350 MB). No usa ords/descargar.sh:
#      sus URL son "latest" y cambiarian las versiones.
#
# Despues, en el servidor:  bash servidor/build_servidor.sh 1.1.0 --ords
#
# Usa el alias "docker-prod" de ~/.ssh/config (ver la bitacora, FASE 6).
# Desde WSL, el ~/.ssh es otro: se usa ssh.exe de Windows si esta.
# =====================================================================

set -euo pipefail
cd "$(dirname "$0")/.."          # oracle19-poc/

SERVIDOR="${SERVIDOR:-docker-prod}"
SSH="${SSH:-$(command -v ssh.exe || command -v ssh)}"
BASE="local/oracle19c-se2:19.3.0"
BASE_ORDS="local/oracle19c-se2-ords:19.3.0"
# LogLevel=ERROR: el ssh de Git Bash avisa en cada conexion que el
# servidor no ofrece intercambio de llaves post-cuantico. No es nuestro.
remoto() { "$SSH" -o BatchMode=yes -o ServerAliveInterval=30 -o LogLevel=ERROR "$SERVIDOR" "$@"; }

echo "== 1/3 Codigo"
# Se sube el COMMIT, no el arbol de trabajo: asi cada build del servidor
# se puede rastrear a un commit. Con cambios sin commitear se aborta.
if [ -n "$(git status --porcelain -- .)" ] && [ "${FORZAR:-}" != "1" ]; then
  echo "ERROR: hay cambios sin commitear en oracle19-poc/. Commitea primero"
  echo "       (o FORZAR=1 para subir el ultimo commit igual, sin esos cambios)."
  exit 1
fi
COMMIT=$(git rev-parse --short HEAD)
# Desde oracle19-poc/, git archive ya se limita a esta carpeta. (La forma
# HEAD:oracle19-poc da un arbol VACIO sin error: por eso el chequeo.)
# core.autocrlf=false: con autocrlf=true (Windows), git archive desde una
# subcarpeta entrega los .sh con CRLF pese a eol=lf, y en Linux fallan.
git -c core.autocrlf=false archive --format=tar --prefix=oracle19-poc/ HEAD \
  | remoto "tar -xf - -C ~ && test -f ~/oracle19-poc/servidor/build_servidor.sh"
CRLF=$(remoto "cd ~/oracle19-poc && grep -rlI \$'\r' --include='*.sh' . || true")
if [ -n "$CRLF" ]; then
  echo "ERROR: estos .sh llegaron con CRLF al servidor:"; echo "$CRLF"; exit 1
fi
remoto "echo $COMMIT > ~/oracle19-poc/COMMIT.txt"
echo "   ~/oracle19-poc actualizado al commit $COMMIT"

echo "== 2/3 Imagen base ($BASE)"
if remoto "docker image inspect $BASE >/dev/null 2>&1"; then
  echo "   ya esta en el servidor"
  # El notebook puede ya no tenerla (se libero el disco): no hay con que
  # comparar, y la del servidor es la que se verifico al subirla.
  if ! docker image inspect "$BASE" >/dev/null 2>&1; then
    echo "   (no esta en el notebook: no se comparan capas)"
    SIN_LOCAL=1
  fi
else
  echo "   mandando ~9,5 GB (unos 10 min; no hay barra de progreso)..."
  docker save "$BASE" | gzip -1 | remoto "pigz -dc | docker load"
fi
# Mismo contenido que la del notebook: se comparan las capas, no el ID
# (Docker Desktop y el Docker del servidor calculan el ID distinto).
if [ -z "${SIN_LOCAL:-}" ]; then
  if [ "$(docker image inspect -f '{{.RootFS.Layers}}' "$BASE")" != \
       "$(remoto "docker image inspect -f '{{.RootFS.Layers}}' $BASE")" ]; then
    echo "ERROR: $BASE del servidor no tiene las mismas capas que la del notebook."
    exit 1
  fi
  echo "   capas identicas a las del notebook"
fi

echo "== 3/3 Java + ORDS para construir $BASE_ORDS"
if remoto "test -x ~/oracle19-poc/ords/downloads/jre/bin/java -a -e ~/oracle19-poc/ords/downloads/ords/bin/ords"; then
  echo "   ya estan en el servidor"
else
  TMP=oracle19-extraer-ords
  docker rm -f "$TMP" >/dev/null 2>&1 || true
  docker create --name "$TMP" "$BASE_ORDS" >/dev/null
  trap 'docker rm -f "$TMP" >/dev/null 2>&1 || true' EXIT
  remoto "mkdir -p ~/oracle19-poc/ords/downloads/apex && cd ~/oracle19-poc/ords/downloads && rm -rf jre ords jre21 product"
  docker cp "$TMP:/opt/java/jre21" - | remoto "cd ~/oracle19-poc/ords/downloads && tar -xf - && mv jre21 jre"
  docker cp "$TMP:/opt/oracle/ords/product" - | remoto "cd ~/oracle19-poc/ords/downloads && tar -xf - && mv product ords"
fi
remoto 'cd ~/oracle19-poc/ords/downloads && ./jre/bin/java -version 2>&1 | head -1 && JAVA_HOME=$PWD/jre PATH=$PWD/jre/bin:$PATH bash ords/bin/ords --version 2>&1 | tail -1' | sed 's/^/   /'
echo "   (comparar con ords/VERSIONES.txt)"

echo
echo "Listo. En el servidor:"
echo "  ssh $SERVIDOR"
echo "  cd ~/oracle19-poc && bash servidor/build_servidor.sh 1.1.0 --ords"
