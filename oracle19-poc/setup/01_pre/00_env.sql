-- =====================================================================
-- 00_env.sql — Variables y sesion comun a todos los scripts de 01_pre
-- Ejecutar como SYS/SYSTEM. Se invoca desde install.sh, no suelto.
-- =====================================================================

SET DEFINE ON
SET SQLBLANKLINES ON
WHENEVER SQLERROR CONTINUE

-- Nombre del PDB donde vive todo. Cambiar aqui si el compose usa otro.
DEFINE PDB_NAME = DEMOPDB

-- Password de los esquemas de la PoC. NO es un secreto: esta base es
-- local, descartable y sin datos reales. Para un entorno compartido,
-- parametrizar via .env y pasarlo con -v al invocar sqlplus.
-- Sin comillas: SQL*Plus las trata como parte del valor en algunos
-- casos y quedaria IDENTIFIED BY ""Grl_Poc_2026"". Las comillas van en
-- el punto de uso.
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
