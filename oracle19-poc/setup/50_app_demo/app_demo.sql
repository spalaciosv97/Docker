-- =====================================================================
-- app_demo.sql — Esquema de ejemplo, se instala CON la imagen
--
-- Simula al desarrollador que llega y agrega SU_ESQUEMA sobre la base
-- institucional. Se incluye en la imagen a proposito: quien la levante
-- encuentra un ejemplo andando de como consumir GENERALIDADES desde su
-- propio esquema, en vez de tener que deducirlo.
--
-- Ejecutar como SYS/SYSTEM.
-- =====================================================================

ALTER SESSION SET CONTAINER = DEMOPDB;

-- SET SERVEROUTPUT va DESPUES del ALTER SESSION: cambiar de contenedor
-- resetea el estado PL/SQL de la sesion y desactiva DBMS_OUTPUT.
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 60
WHENEVER SQLERROR CONTINUE

-- Reejecutable
BEGIN
  EXECUTE IMMEDIATE 'DROP USER APP_DEMO CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;  -- no existia, normal la primera vez
END;
/

CREATE USER APP_DEMO IDENTIFIED BY "&APP_DEMO_PWD."
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE TO APP_DEMO;
GRANT CREATE PROCEDURE, CREATE VIEW TO APP_DEMO;

-- Grants DIRECTOS sobre cada objeto, NO via rol: al compilar PL/SQL
-- Oracle ignora los privilegios heredados de roles, y los packages
-- quedarian INVALID. Es el error mas comun al montar un esquema nuevo
-- sobre GENERALIDADES.
GRANT EXECUTE ON GENERALIDADES.PKG_UTILIDADES        TO APP_DEMO;
GRANT EXECUTE ON GENERALIDADES.PKG_LOG               TO APP_DEMO;
GRANT EXECUTE ON GENERALIDADES.PKG_VALIDATOR         TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_REFERENCIA_ITEM   TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_PERSONA           TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_COMUNAS_VW        TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_PAISES_VW         TO APP_DEMO;

PROMPT ==> APP_DEMO creado

CREATE OR REPLACE PACKAGE APP_DEMO.PKG_PRUEBA AS
  -- Usa una funcion real de la libreria institucional.
  FUNCTION convertir(p_valor IN VARCHAR2) RETURN NUMBER;
  -- Lee datos maestros a traves de una vista institucional.
  FUNCTION contar_comunas RETURN NUMBER;
  -- Lee el fixture de personas.
  FUNCTION contar_personas RETURN NUMBER;
  -- Escribe en el log institucional, que vive en el esquema AUDITOR.
  PROCEDURE registrar(p_titulo IN VARCHAR2);
END PKG_PRUEBA;
/

CREATE OR REPLACE PACKAGE BODY APP_DEMO.PKG_PRUEBA AS

  FUNCTION convertir(p_valor IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    -- OJO: TO_FLOAT hace REPLACE(valor,'.',',') y luego TO_NUMBER, o
    -- sea que asume una sesion con coma decimal. Sin
    -- NLS_NUMERIC_CHARACTERS = ',.' devuelve NULL sin avisar.
    RETURN GENERALIDADES.PKG_UTILIDADES.TO_FLOAT(p_valor);
  END convertir;

  FUNCTION contar_comunas RETURN NUMBER IS
    l_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_n FROM GENERALIDADES.GRL_COMUNAS_VW;
    RETURN l_n;
  END contar_comunas;

  FUNCTION contar_personas RETURN NUMBER IS
    l_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_n FROM GENERALIDADES.GRL_PERSONA;
    RETURN l_n;
  END contar_personas;

  PROCEDURE registrar(p_titulo IN VARCHAR2) IS
  BEGIN
    -- REGISTRA_LOG, no INSERT_REGISTRO: este ultimo exige que el
    -- llamador le pase un LOG_ID no nulo. REGISTRA_LOG lo genera solo
    -- con la secuencia de AUDITOR.
    GENERALIDADES.PKG_LOG.REGISTRA_LOG(
      p_app_id   => 101,
      p_log_json => '{"origen":"APP_DEMO","prueba":true}',
      p_titulo   => p_titulo);
  END registrar;

END PKG_PRUEBA;
/

PROMPT
PROMPT === Estado de APP_DEMO (debe estar todo VALID) ======================
SELECT object_type, object_name, status
  FROM dba_objects WHERE owner = 'APP_DEMO' ORDER BY object_type;

SELECT name, type, line, text FROM dba_errors WHERE owner = 'APP_DEMO'
 ORDER BY name, sequence;
