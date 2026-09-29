#!/usr/bin/env bash
# =====================================================================
# 50_ords.sh — Levanta ORDS en cada arranque del contenedor
#
# Va horneado en /opt/oracle/scripts/startup/. La imagen oficial de
# Oracle recorre ese directorio en CADA arranque, despues de imprimir
# "DATABASE IS READY TO USE!".
#
# UNA regla que no se puede romper: este script NO puede quedarse
# esperando. runOracle.sh aguarda a que termine antes de crear el
# marcador que usa el healthcheck; si ORDS corriera en primer plano, el
# contenedor quedaria en "starting" para siempre y docker compose up
# pareceria colgado. Por eso ORDS se lanza con nohup y &.
#
# (runUserScripts.sh hace ". este_archivo": las funciones y variables
# de aca quedan en su shell. De ahi los nombres con prefijo _ords.)
# =====================================================================

_ords_home=/opt/oracle/ords
_ords_pidf=$_ords_home/logs/ords.pid

_ords_arrancar() {
  if [ ! -f "$_ords_home/config/databases/default/pool.xml" ]; then
    echo "AVISO: ORDS no esta configurado en esta imagen; no se levanta."
    return 0
  fi

  # El pidfile podria venir de otra corrida (o, si algo fallo al
  # construir, horneado en la imagen). No alcanza con que el PID exista:
  # hay que confirmar que ese proceso es realmente ORDS. Si no, este
  # script creeria que ORDS ya corre y no lo levantaria nunca.
  if [ -f "$_ords_pidf" ]; then
    _p=$(cat "$_ords_pidf")
    if kill -0 "$_p" 2>/dev/null && tr '\0' ' ' < "/proc/$_p/cmdline" 2>/dev/null | grep -q ords; then
      echo "ORDS ya esta corriendo (pid $_p)."
      return 0
    fi
    rm -f "$_ords_pidf"
  fi

  mkdir -p "$_ords_home/logs"
  nohup bash "$_ords_home/bin/start_ords.sh" >> "$_ords_home/logs/ords.log" 2>&1 &
  echo "ORDS lanzado en segundo plano. Responde en ~30-60 s en el puerto 8080."
  echo "Log: $_ords_home/logs/ords.log"
}

_ords_arrancar
