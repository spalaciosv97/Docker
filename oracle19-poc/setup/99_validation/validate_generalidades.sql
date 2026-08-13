-- =====================================================================
-- validate_generalidades.sql
--
-- Ejecutar como SYS/SYSTEM despues de toda la instalacion.
--
-- CRITERIO DE EXITO: cero objetos invalidos (consulta 2).
--
-- El conteo de objetos (consulta 3) es informativo. NO se compara con
-- los numeros del CONTEXTO (40 tablas, 41 vistas, 47 packages): esos
-- salieron de DESARROLLO, que esta mas sucio. La comparacion valida es
-- contra el inventario de QA, que hay que pedirle al compañero con:
--
--   SELECT object_type, COUNT(*) FROM dba_objects
--    WHERE owner='GENERALIDADES' AND object_type NOT LIKE '%LOB%'
--    GROUP BY object_type ORDER BY 1;
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 200
SET DEFINE OFF
COLUMN object_name FORMAT A40
COLUMN text        FORMAT A80
COLUMN name        FORMAT A30

ALTER SESSION SET CONTAINER = DEMOPDB;

SPOOL validate_generalidades.log

PROMPT
PROMPT === 1. Oracle Text instalado? =========================================
-- Si no aparece CONTEXT o no esta VALID, el unico objeto afectado es
-- GRL_ARCHIVO_VERSION_JSON_IDX (indice JSON). Es una limitacion
-- conocida y aceptada de la PoC, no un fallo de la instalacion.
SELECT comp_id, comp_name, status, version FROM dba_registry
 WHERE comp_id IN ('CONTEXT','CATALOG','CATPROC') ORDER BY comp_id;

PROMPT
PROMPT === 2. CRITERIO PRINCIPAL: objetos invalidos (debe estar vacio) ======
SELECT object_type, object_name, status
  FROM dba_objects
 WHERE owner = 'GENERALIDADES' AND status <> 'VALID'
 ORDER BY object_type, object_name;

PROMPT
PROMPT === 3. Conteo por tipo (informativo) =================================
SELECT object_type, COUNT(*) AS cantidad
  FROM dba_objects
 WHERE owner = 'GENERALIDADES'
 GROUP BY object_type
 ORDER BY object_type;

PROMPT
PROMPT === 4. Errores de compilacion pendientes =============================
SELECT name, type, line, position, text
  FROM dba_errors
 WHERE owner = 'GENERALIDADES'
 ORDER BY name, sequence;

PROMPT
PROMPT === 5. Nada debe apuntar fuera del PDB ===============================
-- La PoC tiene que funcionar sin conectividad a DEV/QA. Si aparece
-- cualquier DB Link, la instalacion NO es autonoma.
SELECT owner, db_link, host FROM dba_db_links;

PROMPT
PROMPT === 6. Dependencias externas resueltas ===============================
SELECT owner, name, referenced_owner, referenced_name, referenced_type
  FROM dba_dependencies
 WHERE owner = 'GENERALIDADES'
   AND referenced_owner NOT IN ('GENERALIDADES','SYS','PUBLIC')
 ORDER BY referenced_owner, referenced_name, name;

PROMPT
PROMPT === 7. Datos maestros cargados =======================================
SELECT 'GRL_REFERENCIA'      AS tabla, COUNT(*) AS filas FROM GENERALIDADES.GRL_REFERENCIA
UNION ALL
SELECT 'GRL_REFERENCIA_ITEM',        COUNT(*) FROM GENERALIDADES.GRL_REFERENCIA_ITEM
UNION ALL
SELECT 'GRL_PARAMETRO',              COUNT(*) FROM GENERALIDADES.GRL_PARAMETRO;

PROMPT
PROMPT === 8. Las vistas devuelven datos? ===================================
-- Si dan 0, los datos maestros no cargaron o los filtros de las vistas
-- (id_referencia / id_estado) no calzan con lo que se cargo.
SELECT 'GRL_COMUNAS_VW'    AS vista, COUNT(*) AS filas FROM GENERALIDADES.GRL_COMUNAS_VW
UNION ALL
SELECT 'GRL_PAISES_VW',            COUNT(*) FROM GENERALIDADES.GRL_PAISES_VW
UNION ALL
SELECT 'GRL_REGIONES_VW',          COUNT(*) FROM GENERALIDADES.GRL_REGIONES_VW
UNION ALL
SELECT 'GRL_SEXOS_VW',             COUNT(*) FROM GENERALIDADES.GRL_SEXOS_VW
UNION ALL
SELECT 'GRL_ESTADO_ITEM_VW',       COUNT(*) FROM GENERALIDADES.GRL_ESTADO_ITEM_VW
UNION ALL
SELECT 'GRL_OBJETO_LISTA_VW',      COUNT(*) FROM GENERALIDADES.GRL_OBJETO_LISTA_VW;

PROMPT
PROMPT === 9. Charset y acentos ============================================
-- Verifica que la carga no corrompio los acentos. Si aparecen
-- caracteres raros, sqlplus corrio sin NLS_LANG=.AL32UTF8 y hay que
-- recargar 30_data.
SELECT parameter, value FROM nls_database_parameters
 WHERE parameter IN ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');

SELECT id_referencia, nombre, descripcion
  FROM GENERALIDADES.GRL_REFERENCIA
 WHERE descripcion LIKE '%á%' OR descripcion LIKE '%ó%' OR nombre LIKE '%Á%'
 FETCH FIRST 5 ROWS ONLY;

SPOOL OFF
