# =====================================================================
# Dockerfile — Imagen base con Java + ORDS, sobre la de Oracle 19c
#
#   bash ords/construir_base.sh      (no llamar docker build a mano)
#
# Produce local/oracle19c-se2-ords:19.3.0, que es la base de las DOS
# variantes con ORDS (con y sin APEX). La diferencia entre ambas no esta
# aca sino en la base de datos: APEX se instala en los datafiles durante
# el build, asi que esta capa es identica para las dos.
#
# Aca NO se instala nada en la base de datos (todavia no existe): solo
# se dejan los binarios y los scripts de arranque. La base se crea y se
# configura despues, con build.sh.
# =====================================================================

FROM local/oracle19c-se2:19.3.0

ENV JAVA_HOME=/opt/java/jre21 \
    ORDS_HOME=/opt/oracle/ords \
    ORDS_CONFIG=/opt/oracle/ords/config
ENV PATH=$JAVA_HOME/bin:$ORDS_HOME/product/bin:$PATH

# Los directorios se crean ANTES de copiar y con el dueño correcto. Un
# chown -R despues del COPY duplicaria los ~100 MB de ORDS en otra capa.
USER root
RUN mkdir -p /opt/java $ORDS_HOME/product $ORDS_CONFIG $ORDS_HOME/logs $ORDS_HOME/bin && \
    chown -R oracle:dba $ORDS_HOME

# --chmod porque los archivos vienen de un disco NTFS (via WSL) y ahi
# los permisos de ejecucion no son confiables: sin esto, java u ords
# podrian quedar sin el bit +x y fallar con "Permission denied".
COPY --chown=oracle:dba --chmod=0755 downloads/jre/  $JAVA_HOME/
COPY --chown=oracle:dba --chmod=0755 downloads/ords/ $ORDS_HOME/product/
COPY --chown=oracle:dba --chmod=0755 bin/            $ORDS_HOME/bin/

# El script que levanta ORDS en cada arranque del contenedor. Va
# HORNEADO, no montado: un bind mount no quedaria en la imagen que se
# reparte, y ORDS no arrancaria en la maquina de nadie.
COPY --chown=oracle:dba --chmod=0755 startup/50_ords.sh /opt/oracle/scripts/startup/50_ords.sh

EXPOSE 8080
USER oracle
# ENTRYPOINT/CMD se heredan: runOracle.sh sigue siendo el que manda.
