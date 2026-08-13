-- =====================================================================
-- 01_tablespaces.sql — GENERALIDADES_DATA / GENERALIDADES_INDEX
--
-- Adaptado del script que entrego QA. Diferencias respecto al original,
-- y por que:
--
--  1) SIN ruta de datafile. QA usa
--       /u02/app/oracle/oradata/CDBUNAP/pdbunap/tsgeneralidades*.dbf
--     que no existe en el contenedor. Usando OMF (DB_CREATE_FILE_DEST)
--     Oracle elige la ruta solo y el mismo script sirve en QA y en Docker.
--
--  2) CON AUTOEXTEND. QA los crea con 50M fijos; el esquema pesa ~30 MB
--     mas indices y se llenaria (ORA-01653).
--
--  3) Dentro del PDB (lo hace 00_env.sql). En CDB$ROOT esto no aplica.
-- =====================================================================

-- /opt/oracle/oradata es el directorio montado como volumen persistente
-- en la imagen oficial de Oracle, asi que los datafiles sobreviven a
-- recrear el contenedor.
ALTER SYSTEM SET DB_CREATE_FILE_DEST = '/opt/oracle/oradata' SCOPE = BOTH;

CREATE TABLESPACE GENERALIDADES_DATA
  DATAFILE SIZE 100M AUTOEXTEND ON NEXT 25M MAXSIZE 4G;

CREATE TABLESPACE GENERALIDADES_INDEX
  DATAFILE SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 2G;

PROMPT ==> Tablespaces creados

COLUMN file_name FORMAT A70
SELECT tablespace_name, file_name, bytes/1024/1024 AS mb, autoextensible
  FROM dba_data_files
 WHERE tablespace_name LIKE 'GENERALIDADES%'
 ORDER BY tablespace_name;
