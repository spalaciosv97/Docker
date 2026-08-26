#!/usr/bin/env bash
# =====================================================================
# 01_install.sh — Puente para que Oracle instale GENERALIDADES solo
#
# Se monta en /opt/oracle/scripts/setup, que es el directorio que la
# imagen oficial recorre UNA SOLA VEZ, justo despues de crear la base y
# antes de imprimir "DATABASE IS READY TO USE!".
#
# En arranques posteriores la base ya existe, Oracle no vuelve a mirar
# este directorio, y el contenedor levanta en 1-3 min.
#
# Va en carpeta propia a proposito: asi el directorio que Oracle escanea
# contiene exactamente un script y no arrastra nada mas.
#
# IMPORTANTE: este archivo tiene que tener finales de linea LF. El
# .gitattributes lo fuerza; si se edita desde Windows sin eso, bash
# falla con un error que no dice nada util.
# =====================================================================

exec bash /poc/install.sh
