#!/usr/bin/env bash
# =====================================================================
# prueba_caida_bd.sh — Que hace ORDS si la base se cae (lab del servidor)
#
#   bash prueba_caida_bd.sh
#
# Baja la base del contenedor oracle19-lab-ords (ORDS sigue vivo: es otro
# proceso), mira que responden los endpoints, la vuelve a subir y mide
# cuanto tarda ORDS en recuperarse SIN reiniciarlo.
#
# Cada caida dura menos de 3 min: en docker-prod corre autoheal con
# AUTOHEAL_CONTAINER_LABEL=all, que reinicia a la fuerza un contenedor
# unhealthy (el healthcheck del lab tarda ~7 min en declararlo).
# =====================================================================

set -uo pipefail
CONT=oracle19-lab-ords
BASE=http://127.0.0.1:8082

sql() {
  docker exec -i "$CONT" bash -lc 'export ORACLE_SID=DEMOCDB; sqlplus -S "/ as sysdba"' <<SQL
set heading off feedback off pagesize 0
$1
exit
SQL
}

pedir() {   # $1 = ruta; imprime codigo y el cuerpo recortado
  local r cod
  r=$(curl -s -m 20 -w $'\n__COD=%{http_code} __T=%{time_total}s' "$BASE$1")
  cod=$(echo "$r" | grep -o '__COD=[0-9]* __T=[0-9.]*s')
  echo "  GET $1 -> $cod"
  echo "$r" | grep -v '__COD=' | sed -e 's/<[^>]*>//g' | tr -s ' \t' ' ' | grep -v '^ *$' \
    | grep -i -E 'ORA-|PLS-|error|status|comunas|503|500|pool|unavailable|timeout|message|title|cause' \
    | head -8 | cut -c1-220 | sed 's/^/      /'
}

ronda() {
  echo "--- $(date +%T) $1"
  pedir /ords/app_demo/v1/prueba
  pedir /ords/app_demo/v1/prueba-apex
  pedir /ords/sql-developer
}

esperar_ords() {   # cuanto tarda /prueba en volver a 200
  local t0=$(date +%s) cod
  for _ in $(seq 1 60); do
    cod=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$BASE/ords/app_demo/v1/prueba")
    if [ "$cod" = "200" ]; then echo "  /prueba volvio a 200 en $(( $(date +%s) - t0 ))s"; return; fi
    sleep 3
  done
  echo "  /prueba NO volvio a 200 en 3 min (ultimo codigo: $cod)"
}

estado_pdb() {
  echo "  PDB: $(sql "select name||' '||open_mode from v\$pdbs where name='DEMOPDB';" | tr -d '\n')"
}

echo "===== 0. Linea base"
ronda "base arriba"
estado_pdb

echo; echo "===== 1. SHUTDOWN IMMEDIATE (caida ordenada)"
sql "shutdown immediate" | sed 's/^/  /'
ronda "base abajo, al instante"
sleep 30
ronda "base abajo, +30 s"
echo "  proceso ORDS: $(docker top "$CONT" -o pid,args | grep -q '[j]ava.*ords' && echo vivo || echo muerto)"

echo; echo "===== 2. STARTUP"
sql "startup" | sed 's/^/  /'
estado_pdb
esperar_ords
ronda "despues del startup"

echo; echo "===== 3. SHUTDOWN ABORT (caida brusca, como un corte de luz)"
sql "shutdown abort" | sed 's/^/  /'
ronda "base abajo (abort), al instante"
sleep 20

echo; echo "===== 4. STARTUP despues del abort (recuperacion de instancia)"
sql "startup" | sed 's/^/  /'
estado_pdb
esperar_ords
ronda "despues del startup (abort)"

echo; echo "===== Estado final"
docker inspect -f '  contenedor: {{.State.Status}} health={{.State.Health.Status}} reinicios={{.RestartCount}}' "$CONT"
