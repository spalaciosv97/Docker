#!/usr/bin/env bash
# =====================================================================
# stop_ords.sh — Detiene ORDS
#
#   docker exec <contenedor> bash /opt/oracle/ords/bin/stop_ords.sh
#
# Para volver a levantarlo sin reiniciar el contenedor:
#   docker exec <contenedor> bash /opt/oracle/scripts/startup/50_ords.sh
# =====================================================================

PIDF=/opt/oracle/ords/logs/ords.pid

if [ -f "$PIDF" ]; then
  PID=$(cat "$PIDF")
  if kill -0 "$PID" 2>/dev/null; then
    kill -TERM "$PID"
    for _ in $(seq 1 30); do
      kill -0 "$PID" 2>/dev/null || break
      sleep 1
    done
    kill -0 "$PID" 2>/dev/null && kill -KILL "$PID"
    echo "ORDS detenido (pid $PID)."
  else
    echo "ORDS no estaba corriendo."
  fi
  rm -f "$PIDF"
else
  echo "ORDS no estaba corriendo (sin pidfile)."
fi
