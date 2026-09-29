-- =====================================================================
-- 99_validate_ords.sql — Estado de ORDS (y APEX) en DEMOPDB
--
-- Informativo: deja el detalle en validate_ords.log. El veredicto lo
-- saca install_ords.sh preguntandole a la base, y la prueba HTTP la
-- hace build.sh contra el servicio ya levantado.
--
-- Ejecutar como SYS.
-- =====================================================================

ALTER SESSION SET CONTAINER = DEMOPDB;

SET LINESIZE 200
SET PAGESIZE 100
COLUMN comp_id        FORMAT A10
COLUMN comp_name      FORMAT A40
COLUMN version        FORMAT A20
COLUMN status         FORMAT A10
COLUMN owner          FORMAT A20
COLUMN object_name    FORMAT A40
COLUMN parsing_schema FORMAT A20
COLUMN pattern        FORMAT A20
COLUMN name           FORMAT A15
COLUMN uri_template   FORMAT A20
COLUMN method         FORMAT A8
COLUMN source_type    FORMAT A25
COLUMN username       FORMAT A20
COLUMN account_status FORMAT A20

SPOOL validate_ords.log

PROMPT === 1. Version de ORDS instalada ==================================
-- La vista y no ords.installed_version: el package es de derechos del
-- invocador y SYS no le hereda privilegios (ORA-06598).
SELECT version, status FROM ords_metadata.ords_version;

PROMPT
PROMPT === 2. APEX en el registro de componentes =========================
PROMPT (sin filas = APEX NO esta instalado)
SELECT comp_id, comp_name, version, status
  FROM dba_registry WHERE comp_id = 'APEX';

PROMPT
PROMPT === 3. APEX_JSON visible? =========================================
PROMPT (sin filas = cualquier handler con apex_json falla con PLS-00201)
SELECT owner, object_name, object_type, status
  FROM dba_objects
 WHERE object_name = 'APEX_JSON' AND object_type IN ('PACKAGE','SYNONYM');

PROMPT
PROMPT === 4. Objetos invalidos en ORDS y APEX (debe estar vacio) ========
SELECT owner, object_type, object_name, status
  FROM dba_objects
 WHERE (owner = 'ORDS_METADATA' OR owner LIKE 'APEX\_%' ESCAPE '\'
        OR owner = 'FLOWS_FILES')
   AND status <> 'VALID'
 ORDER BY 1, 2, 3;

PROMPT
PROMPT === 5. Esquemas habilitados para REST =============================
SELECT s.parsing_schema, u.pattern, s.status
  FROM ords_metadata.ords_schemas      s
  JOIN ords_metadata.ords_url_mappings u ON u.id = s.url_mapping_id;

PROMPT
PROMPT === 6. Endpoints publicados ======================================
SELECT m.name, t.uri_template, h.method, h.source_type
  FROM ords_metadata.ords_modules   m
  JOIN ords_metadata.ords_templates t ON t.module_id   = m.id
  JOIN ords_metadata.ords_handlers  h ON h.template_id = t.id
 ORDER BY 1, 2;

PROMPT
PROMPT === 7. Usuarios de ORDS ==========================================
SELECT username, account_status FROM dba_users
 WHERE username IN ('ORDS_METADATA','ORDS_PUBLIC_USER') ORDER BY 1;

SPOOL OFF
EXIT
