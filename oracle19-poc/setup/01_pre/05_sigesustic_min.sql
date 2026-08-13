-- =====================================================================
-- 04_sigesustic_min.sql — Dependencia externa SIGESUSTIC (minima)
--
-- GENERALIDADES referencia tres tablas de SIGESUSTIC:
--
--   SGU_APLICACION  <- PKG_PARAMETRO + TRG_VALIDA_GRL_PARAMETRO_FK
--   SGU_SISTEMA     <- PKG_PARAMETRO + TRG_VALIDA_GRL_PARAMETRO_FK
--   SGU_USUARIO     <- TRG_VALIDA_GRL_PARAMETRO_FK
--
-- Todas via SQL dinamico, asi que no bloquean la compilacion, pero SI
-- el INSERT de datos: el trigger valida cada ID_SISTEMA / ID_APLICACION
-- / ID_USUARIO contra estas tablas y lanza ORA-20005 si no existe.
--
-- Estructura completa obtenida de Desarrollo via ALL_TAB_COLUMNS.
-- Los DATA_LENGTH del diccionario vienen en BYTES (800, 1020, 2000,
-- 4000 = 200, 255, 500, 1000 caracteres x 4): el origen usa semantica
-- CHAR. Aqui se declaran en bytes, que es un superconjunto seguro.
-- =====================================================================

CREATE USER SIGESUSTIC IDENTIFIED BY "&SIGE_PWD."
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION TO SIGESUSTIC;

CREATE TABLE SIGESUSTIC.SGU_SISTEMA (
  SIS_ID           NUMBER(*,0)     NOT NULL,
  SIS_NOMBRE       VARCHAR2(800)   NOT NULL,
  SIS_ESTADO       NUMBER(*,0)     NOT NULL,
  SIS_DESCRIPCION  VARCHAR2(4000)  NOT NULL,
  SIS_USER_REG     NUMBER(*,0)     NOT NULL,
  SIS_FECHA_REG    TIMESTAMP(6)    NOT NULL,
  CONSTRAINT PK_SGU_SISTEMA PRIMARY KEY (SIS_ID)
);

CREATE TABLE SIGESUSTIC.SGU_APLICACION (
  APP_ID            NUMBER(*,0)    NOT NULL,
  SIS_ID            NUMBER(*,0)    NOT NULL,
  APP_ICONO         VARCHAR2(2000),
  APP_RUTA          VARCHAR2(2000) NOT NULL,
  APP_NOMBRE        VARCHAR2(800)  NOT NULL,
  APP_DESCRIPCION   VARCHAR2(2000) NOT NULL,
  APP_COLOR         VARCHAR2(200),
  APP_ESTADO        NUMBER(*,0)    NOT NULL,
  APP_FECHA_INICIO  DATE           NOT NULL,
  APP_FECHA_FIN     DATE,
  APP_USER_REG      NUMBER(*,0)    NOT NULL,
  APP_FECHA_REG     TIMESTAMP(6)   NOT NULL,
  CONSTRAINT PK_SGU_APLICACION PRIMARY KEY (APP_ID)
);

CREATE TABLE SIGESUSTIC.SGU_USUARIO (
  USR_ID                     NUMBER(*,0)    NOT NULL,
  USR_ID_PERSONA             NUMBER(*,0)    NOT NULL,
  USR_CORREO                 VARCHAR2(1020) NOT NULL,
  USR_PASSWORD               VARCHAR2(2000),
  USR_FECHA_CAMBIO_PASSWORD  DATE,
  USR_REINTENTOS             NUMBER(*,0)    DEFAULT 0 NOT NULL,
  USR_ESTADO                 NUMBER(*,0)    NOT NULL,
  USR_FECHA_INICIO           DATE           NOT NULL,
  USR_FECHA_FIN              DATE,
  USR_FECHA_BLOQUEO          DATE,
  USR_USER_REG               NUMBER(*,0)    NOT NULL,
  USR_FECHA_REG              TIMESTAMP(6)   NOT NULL,
  CONSTRAINT PK_SGU_USUARIO PRIMARY KEY (USR_ID)
);

-- ---------------------------------------------------------------------
-- Semillas
--
-- Son exactamente los IDs distintos que aparecen en los 23 INSERT de
-- GRL_PARAMETRO exportados de Desarrollo. Sin esto, TRG_VALIDA_
-- GRL_PARAMETRO_FK rechaza la carga con ORA-20005.
--
-- Si mas adelante se cargan mas parametros, hay que ampliar estas
-- listas o el trigger volvera a rechazarlos.
-- ---------------------------------------------------------------------

DECLARE
  TYPE t_ids IS TABLE OF NUMBER;
  l_sistemas    t_ids := t_ids(101, 345, 371, 374, 410, 426, 480, 537, 586);
  l_aplicaciones t_ids := t_ids(101, 399, 434, 448, 462, 464, 465, 467,
                                479, 500, 630, 780);
  l_usuarios    t_ids := t_ids(51, 114);
BEGIN
  FOR i IN 1 .. l_sistemas.COUNT LOOP
    INSERT INTO SIGESUSTIC.SGU_SISTEMA (
      SIS_ID, SIS_NOMBRE, SIS_ESTADO, SIS_DESCRIPCION,
      SIS_USER_REG, SIS_FECHA_REG)
    VALUES (
      l_sistemas(i), 'SISTEMA ' || l_sistemas(i), 1,
      'Semilla PoC Docker - sistema ' || l_sistemas(i),
      1, SYSTIMESTAMP);
  END LOOP;

  FOR i IN 1 .. l_aplicaciones.COUNT LOOP
    INSERT INTO SIGESUSTIC.SGU_APLICACION (
      APP_ID, SIS_ID, APP_RUTA, APP_NOMBRE, APP_DESCRIPCION,
      APP_ESTADO, APP_FECHA_INICIO, APP_USER_REG, APP_FECHA_REG)
    VALUES (
      l_aplicaciones(i), 101, '/poc/' || l_aplicaciones(i),
      'APLICACION ' || l_aplicaciones(i),
      'Semilla PoC Docker - aplicacion ' || l_aplicaciones(i),
      1, SYSDATE, 1, SYSTIMESTAMP);
  END LOOP;

  FOR i IN 1 .. l_usuarios.COUNT LOOP
    INSERT INTO SIGESUSTIC.SGU_USUARIO (
      USR_ID, USR_ID_PERSONA, USR_CORREO, USR_ESTADO,
      USR_FECHA_INICIO, USR_USER_REG, USR_FECHA_REG)
    VALUES (
      l_usuarios(i), l_usuarios(i),
      'usuario' || l_usuarios(i) || '@poc.local', 1,
      SYSDATE, 1, SYSTIMESTAMP);
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Semillas SIGESUSTIC: '
    || l_sistemas.COUNT || ' sistemas, '
    || l_aplicaciones.COUNT || ' aplicaciones, '
    || l_usuarios.COUNT || ' usuarios');
END;
/

-- Grants directos para PKG_PARAMETRO (compila con acceso estatico a
-- SGU_APLICACION / SGU_SISTEMA).
GRANT SELECT ON SIGESUSTIC.SGU_SISTEMA    TO GENERALIDADES;
GRANT SELECT ON SIGESUSTIC.SGU_APLICACION TO GENERALIDADES;
GRANT SELECT ON SIGESUSTIC.SGU_USUARIO    TO GENERALIDADES;

PROMPT ==> SIGESUSTIC listo
