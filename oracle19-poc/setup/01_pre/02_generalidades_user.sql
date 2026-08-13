-- =====================================================================
-- 05_generalidades_user.sql — Usuario GENERALIDADES
--
-- Adaptado del script que entrego QA. Diferencias:
--
--  1) Password parametrizada (00_env.sql) en vez de la de QA
--     hardcodeada. Esta base es local y descartable.
--  2) Los CREATE TABLESPACE salieron a 01_tablespaces.sql.
--  3) Se ejecuta dentro del PDB (00_env.sql). En CDB$ROOT Oracle
--     exigiria el prefijo C## en el nombre del usuario.
--  4) Se agregan los grants que el DDL de QA necesita y que el script
--     original no incluia: CREATE TRIGGER, CREATE TYPE, CREATE ANY
--     INDEX no hace falta (los indices son sobre tablas propias).
-- =====================================================================

CREATE USER GENERALIDADES IDENTIFIED BY "&GRL_PWD."
  DEFAULT TABLESPACE GENERALIDADES_DATA
  TEMPORARY TABLESPACE TEMP;

ALTER USER GENERALIDADES
  QUOTA UNLIMITED ON GENERALIDADES_DATA
  QUOTA UNLIMITED ON GENERALIDADES_INDEX;

GRANT CONNECT, RESOURCE TO GENERALIDADES;
GRANT CREATE TABLE TO GENERALIDADES;

-- OJO: el script de QA tiene dos privilegios que NO EXISTEN en Oracle:
--
--     GRANT ALTER TABLE TO GENERALIDADES;
--     GRANT CREATE VIEW, CREATE SEQUENCE, ALTER SEQUENCE,
--           SELECT SEQUENCE TO GENERALIDADES;
--
-- "ALTER TABLE" y "SELECT SEQUENCE" no son privilegios de sistema (los
-- reales serian ALTER ANY TABLE y SELECT ANY SEQUENCE). Como Oracle
-- evalua cada GRANT como una sola sentencia, el segundo falla COMPLETO
-- y GENERALIDADES se queda sin CREATE VIEW -> las 14 vistas no se
-- crean, y despues fallan ~100 GRANT sobre ellas con ORA-00942.
--
-- Aqui van separados y con los nombres validos. Ninguno de los dos
-- inexistentes hace falta: el dueño de un objeto siempre puede
-- alterarlo y leer sus propias secuencias.
GRANT CREATE VIEW TO GENERALIDADES;
GRANT CREATE SEQUENCE TO GENERALIDADES;
GRANT CREATE SYNONYM TO GENERALIDADES;
GRANT CREATE MATERIALIZED VIEW TO GENERALIDADES;
GRANT CREATE JOB TO GENERALIDADES;

-- Agregados: el DDL de QA crea 5 triggers y 3 tipos. RESOURCE ya trae
-- CREATE TRIGGER/TYPE/PROCEDURE en 19c, pero se declaran explicitos
-- para no depender de como este definido el rol en esta imagen.
GRANT CREATE TRIGGER, CREATE TYPE, CREATE PROCEDURE TO GENERALIDADES;

-- Necesario para el indice Oracle Text sobre JSON
-- (GRL_ARCHIVO_VERSION_JSON_IDX usa CTXSYS.CONTEXT_V2).
-- Si Oracle Text no esta instalado, este grant falla y se ignora:
-- 99_validation lo reporta como limitacion conocida.
GRANT EXECUTE ON CTXSYS.CTX_DDL TO GENERALIDADES;

PROMPT ==> Usuario GENERALIDADES listo

SELECT username, default_tablespace, temporary_tablespace, account_status
  FROM dba_users
 WHERE username IN ('GENERALIDADES', 'AUDITOR', 'SIGESUSTIC')
 ORDER BY username;
