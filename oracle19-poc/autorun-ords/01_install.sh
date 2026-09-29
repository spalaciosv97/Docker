#!/usr/bin/env bash
# =====================================================================
# 01_install.sh — Instalacion de las variantes con ORDS
#
# Mismo mecanismo que autorun/01_install.sh (ver ese archivo), con un
# paso mas: primero GENERALIDADES exactamente igual que en la imagen
# base, y recien despues ORDS (y APEX, si WITH_APEX=true).
#
# El orden es obligatorio: ORDS.ENABLE_SCHEMA necesita que APP_DEMO ya
# exista. Si install.sh falla no se sigue; build.sh lo detecta porque
# falta logs/.../INSTALL_OK.
#
# Finales de linea LF (ver .gitattributes).
# =====================================================================

bash /poc/install.sh && exec bash /poc/install_ords.sh
