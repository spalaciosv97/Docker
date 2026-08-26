-- =====================================================================
-- 00_env.sql — Variables y sesion comun a todos los scripts de 01_pre
-- Ejecutar como SYS/SYSTEM. Se invoca desde install.sh, no suelto.
-- =====================================================================

SET DEFINE ON
SET SQLBLANKLINES ON
WHENEVER SQLERROR CONTINUE

-- Nombre del PDB donde vive todo. Cambiar aqui si el compose usa otro.
DEFINE PDB_NAME = DEMOPDB

-- Las contrasenas NO viven aca: install.sh las inyecta como DEFINE
-- desde el .env antes de llamar a este script. Estos valores son solo
-- el respaldo para poder correr los scripts sueltos al depurar.
--
-- Sin comillas a proposito: SQL*Plus las tratara como parte del valor y
-- quedaria IDENTIFIED BY ""Grl_Poc_2026"". Las comillas van en el punto
-- de uso.
DEFINE GRL_PWD      = Grl_Poc_2026
DEFINE AUDITOR_PWD  = Aud_Poc_2026
DEFINE SIGE_PWD     = Sig_Poc_2026
DEFINE STUB_PWD     = Stub_Poc_2026

ALTER SESSION SET CONTAINER = &PDB_NAME.;

-- SERVEROUTPUT va DESPUES del ALTER SESSION: cambiar de contenedor
-- resetea el estado PL/SQL de la sesion y desactiva DBMS_OUTPUT. Si se
-- activa antes, los PUT_LINE de 03_roles_stub y 05_sigesustic_min se
-- pierden en silencio.
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ==> Conectado al contenedor &PDB_NAME.
