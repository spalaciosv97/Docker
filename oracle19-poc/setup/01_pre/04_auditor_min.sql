-- =====================================================================
-- 03_auditor_min.sql — Dependencia externa AUDITOR (minima)
--
-- GENERALIDADES referencia SOLO dos objetos de AUDITOR en todo el
-- codigo entregado (barrido sobre PACKAGES.sql, PACKAGE_BODIES.sql y
-- la carpeta de QA):
--
--   AUDITOR.LOG_SYSTEM             52 usos  <- BLOQUEA la compilacion
--   AUDITOR.SEQ_LOG_SYSTEM_LOG_ID   1 uso
--
-- Ningun package de AUDITOR es necesario.
--
-- Estructura obtenida de Desarrollo via ALL_TAB_COLUMNS (no habia
-- privilegio de catalogo para DBMS_METADATA). QA confirmo que AUDITOR
-- es identico entre DEV y QA.
-- =====================================================================

CREATE USER AUDITOR IDENTIFIED BY "&AUDITOR_PWD."
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION TO AUDITOR;

-- LOG_JSON es CLOB. El DATA_LENGTH 4000 que reporta el diccionario es
-- el tamano del locator, no del contenido. Importa: PKG_LOG declara sus
-- parametros con %TYPE contra esta columna, y ponerla como VARCHAR2
-- compilaria pero fallaria en runtime con logs largos.
CREATE TABLE AUDITOR.LOG_SYSTEM (
  LOG_ID      NUMBER(*,0)   NOT NULL,
  APP_ID      NUMBER,
  TIPO        NUMBER(*,0),
  TITULO      VARCHAR2(2000),
  ORIGEN      VARCHAR2(2000),
  LOG_JSON    CLOB,
  FECHA_REG   DATE          DEFAULT SYSDATE,
  NOTIFICADO  VARCHAR2(4)   DEFAULT 'N',
  CONSTRAINT PK_LOG_SYSTEM PRIMARY KEY (LOG_ID)
);

-- En DEV la secuencia va en LAST_NUMBER = 20200. Aqui arranca en 1
-- porque no se importan logs historicos.
CREATE SEQUENCE AUDITOR.SEQ_LOG_SYSTEM_LOG_ID
  START WITH 1
  INCREMENT BY 1
  CACHE 20
  MAXVALUE 9999999999999999999999999999;

-- Grants DIRECTOS sobre el objeto, no via rol: al compilar PL/SQL,
-- Oracle ignora los privilegios heredados de roles. Con un GRANT via
-- rol, PKG_LOG quedaria INVALID.
GRANT SELECT, INSERT, UPDATE ON AUDITOR.LOG_SYSTEM            TO GENERALIDADES;
GRANT SELECT                 ON AUDITOR.SEQ_LOG_SYSTEM_LOG_ID TO GENERALIDADES;

PROMPT ==> AUDITOR listo
