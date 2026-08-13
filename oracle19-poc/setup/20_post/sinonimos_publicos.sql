-- =====================================================================
-- sinonimos_publicos.sql — Version Docker
--
-- Adaptado de "No versionables/SINONIMOS PUBLICOS (ejecutar sys).sql".
--
-- Va DESPUES del MASTER: los sinonimos apuntan a objetos de
-- GENERALIDADES que hasta ese momento no existen.
--
-- Se ejecuta como SYS/SYSTEM: CREATE PUBLIC SYNONYM requiere privilegio
-- de sistema que GENERALIDADES no tiene.
--
-- Diferencias respecto al original, y por que:
--
--  1) Sin los "/" sueltos. El original pone "/" despues de sentencias
--     ya terminadas en ";", lo que en SQL*Plus reejecuta la anterior y
--     produce ORA-00955 (name is already used) espurios.
--
--  2) OR REPLACE en los CREATE PUBLIC SYNONYM, para que el script sea
--     reejecutable sin errores.
--
--  3) Los GRANT a CALIDAD se conservan tal cual. CALIDAD existe como
--     usuario stub (01_pre/02_roles_stub.sql), bloqueado y sin
--     privilegios: solo esta para que el GRANT tenga destino.
-- =====================================================================

SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

ALTER SESSION SET CONTAINER = DEMOPDB;

-- --- Packages -------------------------------------------------------

CREATE OR REPLACE PUBLIC SYNONYM CONST FOR GENERALIDADES.PKG_GRL_CONFIG;
GRANT EXECUTE ON GENERALIDADES.PKG_GRL_CONFIG TO CALIDAD;

CREATE OR REPLACE PUBLIC SYNONYM PKG_LOG FOR GENERALIDADES.PKG_LOG;
GRANT EXECUTE ON GENERALIDADES.PKG_LOG TO CALIDAD;

CREATE OR REPLACE PUBLIC SYNONYM REF_ITEM FOR GENERALIDADES.PKG_REFERENCIA_ITEM;
GRANT EXECUTE ON GENERALIDADES.PKG_REFERENCIA_ITEM TO CALIDAD;

CREATE OR REPLACE PUBLIC SYNONYM UTILIDADES FOR GENERALIDADES.PKG_UTILIDADES;
GRANT EXECUTE ON GENERALIDADES.PKG_UTILIDADES TO CALIDAD;

CREATE OR REPLACE PUBLIC SYNONYM VALIDATOR FOR GENERALIDADES.PKG_VALIDATOR;
GRANT EXECUTE ON GENERALIDADES.PKG_VALIDATOR TO CALIDAD;

-- --- Funcion standalone ---------------------------------------------
-- Depende de que el MASTER haya cargado TO_FLOAT_SYN.sql, que el
-- MASTER original de QA no incluia.

CREATE OR REPLACE PUBLIC SYNONYM TO_FLOAT_SYN FOR GENERALIDADES.TO_FLOAT_SYN;
GRANT EXECUTE ON GENERALIDADES.TO_FLOAT_SYN TO CALIDAD;

-- --- Tablas ---------------------------------------------------------

CREATE OR REPLACE PUBLIC SYNONYM REFERENCIA_ITEM FOR GENERALIDADES.GRL_REFERENCIA_ITEM;
GRANT SELECT ON GENERALIDADES.GRL_REFERENCIA_ITEM TO CALIDAD;

CREATE OR REPLACE PUBLIC SYNONYM REFERENCIA FOR GENERALIDADES.GRL_REFERENCIA;
GRANT SELECT ON GENERALIDADES.GRL_REFERENCIA TO CALIDAD;

-- --- Tipo -----------------------------------------------------------

CREATE OR REPLACE PUBLIC SYNONYM T_RULES FOR GENERALIDADES.T_RULES;
GRANT EXECUTE ON GENERALIDADES.T_RULES TO CALIDAD;

PROMPT ==> Sinonimos publicos creados

SELECT synonym_name, table_owner, table_name
  FROM dba_synonyms
 WHERE owner = 'PUBLIC' AND table_owner = 'GENERALIDADES'
 ORDER BY synonym_name;
