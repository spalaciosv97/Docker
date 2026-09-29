#!/usr/bin/env bash
# =====================================================================
# start_ords.sh — Espera al PDB y arranca ORDS en primer plano
#
# No se llama directo: lo lanza en background 50_ords.sh (en cada
# arranque del contenedor) o install_ords.sh (en el build).
# =====================================================================

set -u

export JAVA_HOME=/opt/java/jre21
export PATH="$JAVA_HOME/bin:/opt/oracle/ords/product/bin:$PATH"
# La JVM toma por defecto 1/4 de la RAM. Esto corre en el notebook de
# alguien, al lado de Oracle: se le pone techo.
export JAVA_TOOL_OPTIONS="-Xms256m -Xmx768m"
ORACLE_SID="${ORACLE_SID:-DEMOCDB}"
export ORACLE_SID="${ORACLE_SID^^}"

ORDS_HOME=/opt/oracle/ords
echo "$$" > "$ORDS_HOME/logs/ords.pid"

# Esperar a que DEMOPDB este ABIERTO. Sin esto ORDS levanta igual, pero
# el pool queda en error y TODAS las peticiones devuelven 503 hasta que
# alguien reinicie ORDS: un fallo que se veria en la maquina de otro.
for _ in $(seq 1 60); do
  OM=$(sqlplus -S "/ as sysdba" <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT open_mode FROM v$pdbs WHERE name = 'DEMOPDB';
EXIT
EOF
)
  case "$OM" in *"READ WRITE"*) break ;; esac
  sleep 5
done
echo "$(date -Iseconds) DEMOPDB: ${OM:-sin respuesta}. Arrancando ORDS..."

# exec: ORDS hereda este PID, asi el pidfile de arriba apunta a el.
# El puerto sale del config (standalone.http.port) y la password del
# pool, del wallet que dejo 'ords install'. Cero interaccion.
exec ords --config "$ORDS_HOME/config" serve
