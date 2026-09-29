#!/usr/bin/env bash
# =====================================================================
# descargar.sh — Baja Java, ORDS y APEX a ords/downloads/
#
#   bash ords/descargar.sh
#
# Se corre UNA vez, desde WSL, antes de ords/construir_base.sh. Nada de
# esto se versiona (pesa ~600 MB y se puede volver a bajar).
#
# Que se baja y por que:
#   - Java 21 (Eclipse Temurin, JRE). ORDS es una aplicacion Java y la
#     imagen base de Oracle no trae Java. Temurin es OpenJDK sin
#     restricciones de licencia; la JRE alcanza porque aca no se compila.
#   - ORDS, la version vigente de Oracle.
#   - APEX, solo para la variante ords-apex. Es el que trae APEX_JSON.
#
# Las URL "latest" hacen que dos corridas en fechas distintas puedan
# bajar versiones distintas. Por eso al final se registra exactamente
# que se bajo, con su hash, en ords/VERSIONES.txt: esa es la
# version que queda en la imagen y la que va al CHANGELOG.
# =====================================================================

set -euo pipefail

cd "$(dirname "$0")"
mkdir -p downloads
cd downloads

JRE_URL="https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jre/hotspot/normal/eclipse"
ORDS_URL="https://download.oracle.com/otn_software/java/ords/ords-latest.zip"
APEX_URL="https://download.oracle.com/otn_software/apex/apex-latest.zip"

# Se baja a .part y se renombra al terminar. Es la misma leccion del
# docker load fallido: un archivo con su nombre definitivo pero a medio
# bajar no se distingue de uno completo hasta que algo revienta despues.
bajar() {
  local url="$1" destino="$2"
  if [ -f "$destino" ]; then
    echo "Ya existe $destino — no se vuelve a bajar."
    return
  fi
  echo "Bajando $destino ..."
  curl -fL --retry 3 -o "${destino}.part" "$url"
  mv "${destino}.part" "$destino"
}

bajar "$JRE_URL"  jre21.tar.gz
bajar "$ORDS_URL" ords.zip
bajar "$APEX_URL" apex.zip

echo "Descomprimiendo..."
# Se descomprime aca y no dentro del Dockerfile: la imagen base de
# Oracle Linux 7 slim no trae unzip, y OL7 esta fuera de soporte, asi
# que instalar paquetes con yum en el build seria apostar a que sus
# repositorios sigan respondiendo.
rm -rf jre ords apex
mkdir jre && tar -xzf jre21.tar.gz -C jre --strip-components=1
mkdir ords && unzip -q ords.zip -d ords
unzip -q apex.zip          # crea apex/

echo "Registrando versiones..."
{
  echo "Descargado: $(date -Iseconds)"
  echo
  echo "--- Java"
  jre/bin/java -version 2>&1
  echo
  echo "--- ORDS"
  JAVA_HOME="$PWD/jre" PATH="$PWD/jre/bin:$PATH" bash ords/bin/ords --version 2>&1 | tail -3
  echo
  echo "--- APEX (la version exacta queda en dba_registry al instalarlo)"
  ls apex/apxrtins.sql
  echo
  echo "--- SHA256"
  sha256sum jre21.tar.gz ords.zip apex.zip
} > ../VERSIONES.txt

cat ../VERSIONES.txt
echo
echo "Listo. Siguiente paso: bash ords/construir_base.sh"
