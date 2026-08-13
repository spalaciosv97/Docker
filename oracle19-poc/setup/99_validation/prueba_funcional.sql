-- =====================================================================
-- prueba_funcional.sql — Demuestra el objetivo de la PoC
--
-- Ejecutar como SYS/SYSTEM, DESPUES de que validate_generalidades.sql
-- de cero objetos invalidos.
--
-- No basta con que los objetos "existan": hay que demostrar que un
-- esquema de aplicacion NUEVO puede consumir las librerias
-- institucionales, que es exactamente lo que pidio el jefe.
--
-- Simula al desarrollador que llega y agrega SU_ESQUEMA sobre la
-- imagen base.
-- =====================================================================

ALTER SESSION SET CONTAINER = DEMOPDB;

-- OJO con el orden: SET SERVEROUTPUT tiene que ir DESPUES del ALTER
-- SESSION SET CONTAINER. Cambiar de contenedor resetea el estado PL/SQL
-- de la sesion y desactiva DBMS_OUTPUT, asi que si va antes los
-- PUT_LINE se pierden en silencio.
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 60
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

-- PKG_UTILIDADES.TO_FLOAT hace REPLACE(valor,'.',',') y despues
-- TO_NUMBER, o sea que asume una sesion con la coma como separador
-- decimal. Con el default del contenedor (punto decimal) devuelve NULL
-- sin avisar. Es una dependencia de locale del codigo institucional:
-- cualquier backend que llame a estas librerias tiene que fijar esto.
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';

-- --- El desarrollador crea su esquema --------------------------------

-- Reejecutable: se borra el esquema anterior si quedo de una corrida
-- previa, para que el script se pueda repetir sin ensuciar la salida
-- con ORA-01920 (user name conflicts).
BEGIN
  EXECUTE IMMEDIATE 'DROP USER APP_DEMO CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;  -- no existia, es lo normal la primera vez
END;
/

CREATE USER APP_DEMO IDENTIFIED BY "App_Demo_2026"
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE TO APP_DEMO;
GRANT CREATE PROCEDURE TO APP_DEMO;

-- Grants DIRECTOS: PL/SQL no ve privilegios heredados de roles al
-- compilar. Si estos fueran via rol, PKG_PRUEBA quedaria INVALID.
GRANT EXECUTE ON GENERALIDADES.PKG_UTILIDADES      TO APP_DEMO;
GRANT EXECUTE ON GENERALIDADES.PKG_LOG             TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_REFERENCIA_ITEM TO APP_DEMO;
GRANT SELECT  ON GENERALIDADES.GRL_COMUNAS_VW      TO APP_DEMO;

PROMPT ==> APP_DEMO creado

-- --- Su package consume las librerias institucionales ----------------

CREATE OR REPLACE PACKAGE APP_DEMO.PKG_PRUEBA AS
  -- Usa una funcion real de la libreria institucional.
  FUNCTION convertir(p_valor IN VARCHAR2) RETURN NUMBER;
  -- Lee datos maestros institucionales a traves de una vista.
  FUNCTION contar_comunas RETURN NUMBER;
  -- Escribe en el log institucional, que vive en el esquema AUDITOR.
  PROCEDURE registrar(p_titulo IN VARCHAR2);
END PKG_PRUEBA;
/

CREATE OR REPLACE PACKAGE BODY APP_DEMO.PKG_PRUEBA AS

  FUNCTION convertir(p_valor IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN GENERALIDADES.PKG_UTILIDADES.TO_FLOAT(p_valor);
  END convertir;

  FUNCTION contar_comunas RETURN NUMBER IS
    l_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_n FROM GENERALIDADES.GRL_COMUNAS_VW;
    RETURN l_n;
  END contar_comunas;

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

PROMPT
PROMPT === Ejecucion real ==================================================
-- Si esto devuelve valores, un esquema externo esta usando de verdad
-- las librerias de GENERALIDADES. Ese es el resultado que buscaba la
-- PoC.

DECLARE
  l_num     NUMBER;
  l_comunas NUMBER;
  l_logs    NUMBER;
BEGIN
  l_num := APP_DEMO.PKG_PRUEBA.convertir('123.45');
  DBMS_OUTPUT.PUT_LINE('PKG_UTILIDADES.TO_FLOAT           = ' || l_num);

  l_comunas := APP_DEMO.PKG_PRUEBA.contar_comunas;
  DBMS_OUTPUT.PUT_LINE('Comunas visibles desde APP_DEMO   = ' || l_comunas);

  APP_DEMO.PKG_PRUEBA.registrar('Prueba funcional PoC Docker');
  SELECT COUNT(*) INTO l_logs FROM AUDITOR.LOG_SYSTEM;
  DBMS_OUTPUT.PUT_LINE('Filas en AUDITOR.LOG_SYSTEM       = ' || l_logs);

  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('==> Un esquema externo consumio GENERALIDADES OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FALLO: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/

PROMPT
PROMPT === Lo que quedo escrito en el log institucional =====================
COLUMN titulo FORMAT A32
COLUMN log_json FORMAT A40
SELECT log_id, app_id, titulo, log_json FROM AUDITOR.LOG_SYSTEM
 ORDER BY log_id DESC FETCH FIRST 3 ROWS ONLY;
