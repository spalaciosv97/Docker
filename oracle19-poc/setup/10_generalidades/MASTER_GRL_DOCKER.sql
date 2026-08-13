-- =====================================================================
-- MASTER_GRL_DOCKER.sql
--
-- Version Docker/Linux del "MASTER GRL.sql" que entrego QA.
-- El original NO se modifica: esta es una copia adaptada.
--
-- Diferencias respecto al original, y por que:
--
--  1) RUTAS RELATIVAS. El original apunta a
--       C:\Users\Camilo Donoso\Documents\TESTING\BBDD QA\GENERALIDADES
--     que no existe dentro del contenedor Linux.
--     Ademas las carpetas se renombraron sin espacios
--     ("No versionables" -> no_versionables) porque el @ de SQL*Plus
--     se lleva mal con rutas con espacios.
--
--  2) TYPO CORREGIDO. El original define BASE_PATH_NO_VERSIONABLES pero
--     luego referencia &BASE_PATH_NO_VERSIONALES. (falta la B). Tal
--     cual, SQL*Plus pide el valor por prompt en cada una de las 74
--     lineas y el script no corre solo.
--
--  3) SEQUENCES Y TYPES ADELANTADOS. En el original van al final,
--     despues de los triggers. Pero TRGG_ARCHIVO y TRGG_ARCHIVO_VERSION
--     usan SEC_ARCHIVOS_*.NEXTVAL, asi que se crearian INVALID y
--     habria que recompilarlos. Ahora van antes.
--
--  4) PACKAGES.sql / PACKAGE_BODIES.sql en vez de los 23 archivos
--     sueltos de versionables/. Mismo contenido, y ademas incluye los
--     bodies, que la primera entrega no traia.
--     Se excluyeron los 13 packages de test (PKG_TEST_*, PKG_EXAMPLE,
--     PKG_COMPARADOR) que QA confirmo que se le pasaron por error.
--
--  5) VIEWS.sql agregado (13 vistas). El MASTER original no crea
--     ninguna vista, pese a que los package bodies las usan.
--
--  6) extra/ con los 2 objetos que faltaban en la entrega y que los
--     bodies referencian: GRL_PARAMETRO_ROL y GRL_COMUNAS_VW.
--
--  7) TO_FLOAT_SYN.sql agregado. El MASTER original nunca lo carga,
--     pese a que el script de sinonimos publicos lo referencia.
--
--  8) SPOOL + WHENEVER SQLERROR CONTINUE, para juntar TODOS los errores
--     en una pasada en vez de descubrirlos de a uno.
--
-- Ejecutar CONECTADO COMO GENERALIDADES, con el directorio actual en
-- esta carpeta. Lo hace install.sh.
-- =====================================================================

SET DEFINE OFF
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO OFF
SET FEEDBACK ON
SET LINESIZE 200
SET PAGESIZE 100
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR CONTINUE

-- Ruta absoluta a proposito: este script se ejecuta con el directorio
-- actual en su propia carpeta (ver install.sh), que esta montada de
-- solo lectura. El spool tiene que salir a un directorio con escritura.
SPOOL /poc/logs/install_generalidades.log

SELECT 'Instalando como ' || USER
    || ' en ' || SYS_CONTEXT('USERENV','CON_NAME') AS inicio FROM dual;

PROMPT
PROMPT ============================================================
PROMPT  FASE 1 - TABLAS
PROMPT ============================================================
-- Orden original de QA (18 tablas) + GRL_PARAMETRO_ROL, que faltaba.

@@no_versionables/GRL_ARCHIVO.sql
@@no_versionables/GRL_ARCHIVO_VERSION.sql
@@no_versionables/GRL_ATRIBUTO.sql
@@no_versionables/GRL_COMPONENTE.sql
@@no_versionables/GRL_DATO_ELEMENTO.sql
@@no_versionables/GRL_DIRECCION.sql
@@no_versionables/GRL_ELEMENTO.sql
@@no_versionables/GRL_ELEMENTO_PADRE.sql
@@no_versionables/GRL_ESTRUCTURA.sql
@@no_versionables/GRL_PARAMETRO.sql
@@no_versionables/GRL_PERSONA.sql
@@no_versionables/GRL_PERSONA_DATO_PERSONAL.sql
@@no_versionables/GRL_PERSONA_DIRECCION.sql
@@no_versionables/GRL_REFERENCIA.sql
@@no_versionables/GRL_REFERENCIA_ITEM.sql
@@no_versionables/GRL_REFERENCIA_ROL.sql
@@no_versionables/GRL_REFERENCIA_SISTEMA.sql
@@no_versionables/GRL_SUBCOMPONENTE.sql
@@extra/GRL_PARAMETRO_ROL.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 2 - SECUENCIAS Y TIPOS
PROMPT ============================================================
-- Adelantados respecto al original: los triggers de la FASE 4 usan
-- SEC_ARCHIVOS_*.NEXTVAL y se crearian invalidos si van despues.

@@no_versionables/SEQUENCES.sql
@@no_versionables/TYPES.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 3 - INDICES Y PRIMARY KEYS
PROMPT ============================================================

@@no_versionables/SYS_C0022298.sql
@@no_versionables/GRL_ARCHIVO_IDX1.sql
@@no_versionables/GRL_ARCHIVO_IDX2.sql
@@no_versionables/SYS_C0022703.sql
@@no_versionables/GRL_ARCHIVO_VERSION_IDX1.sql
@@no_versionables/GRL_ARCHIVO_VERSION_IDX2.sql
-- GRL_ARCHIVO_VERSION_JSON_IDX movido a la FASE 5B: necesita que exista
-- primero el CHECK (metadata IS JSON).
@@no_versionables/GLR_ATRIBUTOS_PK.sql
@@no_versionables/GRL_COMPONENTE_PK.sql
@@no_versionables/GRL_DATO_ELEMENTO_PK.sql
@@no_versionables/SYS_C0021566.sql
@@no_versionables/GRL_ELEMENTO_PK.sql
@@no_versionables/GRL_ELEMENTO_PADRE_PK.sql
@@no_versionables/SYS_C0022779.sql
@@no_versionables/PARAMETRO_PK.sql
@@no_versionables/IDX_PARAMETRO_VIGENTE.sql
@@no_versionables/GRL_PERSONAS_PK.sql
@@no_versionables/GDP_DATOSPERSONA_PK.sql
@@no_versionables/GRL_REFERENCIA_PK.sql
@@no_versionables/GRL_REFERENCIA_ITEM_PK.sql
@@no_versionables/IDX_REFITEM_VALIDACION.sql
@@no_versionables/IDX_REFERENCIA_ITEM_VIGENTE.sql
@@no_versionables/PK_REFERENCIA_ROL.sql
@@no_versionables/PK_REFERENCIA_SISTEMA.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 4 - TRIGGERS
PROMPT ============================================================
-- A los 5 se les agrego el terminador "/" que faltaba en el original.
-- Sin el, SQL*Plus no envia el bloque y el trigger nunca se crea.

@@no_versionables/TRGG_ARCHIVO.sql
@@no_versionables/TRGG_ARCHIVO_VERSION.sql
@@no_versionables/INSERT_ID_DIRECCION.sql
@@no_versionables/TRG_VALIDA_GRL_PARAMETRO.sql
@@no_versionables/TRG_VALIDA_GRL_PARAMETRO_FK.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 5 - CONSTRAINTS Y FOREIGN KEYS
PROMPT ============================================================

@@no_versionables/GRL_ARCHIVO_CONSTRAINT.sql
@@no_versionables/GRL_ARCHIVO_VERSION_CONSTRAINT.sql
@@no_versionables/GRL_ATRIBUTO_CONSTRAINT.sql
@@no_versionables/GRL_COMPONENTE_CONSTRAINT.sql
@@no_versionables/GRL_DATO_ELEMENTO_CONSTRAINT.sql
@@no_versionables/GRL_DIRECCION_CONSTRAINT.sql
@@no_versionables/GRL_ELEMENTO_CONSTRAINT.sql
@@no_versionables/GRL_ELEMENTO_PADRE_CONSTRAINT.sql
@@no_versionables/GRL_ESTRUCTURA_CONSTRAINT.sql
@@no_versionables/GRL_PARAMETRO_CONSTRAINT.sql
@@no_versionables/GRL_PERSONA_CONSTRAINT.sql
@@no_versionables/GRL_PERSONA_DATO_PERSONAL_CONSTRAINT.sql
@@no_versionables/GRL_PERSONA_DIRECCION_CONSTRAINT.sql
@@no_versionables/GRL_REFERENCIA_CONSTRAINT.sql
@@no_versionables/GRL_REFERENCIA_ITEM_CONSTRAINT.sql
@@no_versionables/GRL_REFERENCIA_ROL_CONSTRAINT.sql
@@no_versionables/GRL_REFERENCIA_SISTEMA_CONSTRAINT.sql
@@no_versionables/GRL_SUBCOMPONENTE_CONSTRAINT.sql
@@no_versionables/GRL_ATRIBUTO_REFCONSTRAINT.sql
@@no_versionables/GRL_COMPONENTE_REFCONSTRAINT.sql
@@no_versionables/GRL_DATO_ELEMENTO_REFCONSTRAINT.sql
@@no_versionables/GRL_ELEMENTO_REFCONSTRAINT.sql
@@no_versionables/GRL_ELEMENTO_PADRE_REFCONSTRAINT.sql
@@no_versionables/GRL_ESTRUCTURA_REFCONSTRAINT.sql
@@no_versionables/GRL_SUBCOMPONENTE_REFCONSTRAINT.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 5B - INDICE ORACLE TEXT SOBRE JSON
PROMPT ============================================================
-- Movido aqui desde la FASE 3. El indice usa
-- PARAMETERS ('SIMPLIFIED_JSON'), que Oracle Text solo acepta si la
-- columna ya tiene el CHECK (metadata IS JSON) — y ese constraint lo
-- crea GRL_ARCHIVO_VERSION_CONSTRAINT.sql en la FASE 5.
-- En el orden original fallaba con DRG-10720.

@@no_versionables/GRL_ARCHIVO_VERSION_JSON_IDX.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 6 - VISTAS
PROMPT ============================================================
-- Las 13 de VIEWS.sql + GRL_COMUNAS_VW, que no venia en la entrega.
-- Todas proyectan GRL_REFERENCIA_ITEM: quedan vacias hasta que se
-- carguen los datos maestros de 30_data.

@@VIEWS.sql
@@extra/GRL_COMUNAS_VW.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 7 - PACKAGE SPECS
PROMPT ============================================================
-- 23 specs (sin los 13 de test).

@@packages/PACKAGES.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 8 - FUNCION STANDALONE
PROMPT ============================================================
-- TO_FLOAT_SYN llama a PKG_UTILIDADES, por eso va despues de los specs.

@@no_versionables/TO_FLOAT_SYN.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 9 - PACKAGE BODIES
PROMPT ============================================================
-- 22 bodies. PKG_GRL_CONFIG no tiene body: es solo constantes.

@@packages/PACKAGE_BODIES.sql

PROMPT
PROMPT ============================================================
PROMPT  FASE 10 - RECOMPILACION
PROMPT ============================================================
-- Bloque del MASTER original: reintenta compilar lo invalido hasta 5
-- veces, para resolver dependencias circulares entre packages.

BEGIN
  FOR i IN 1..5 LOOP
    FOR rec IN (
      SELECT object_name, object_type
        FROM user_objects
       WHERE object_type IN ('PACKAGE','PACKAGE BODY','VIEW','TRIGGER','FUNCTION')
         AND status = 'INVALID'
    ) LOOP
      BEGIN
        IF rec.object_type = 'PACKAGE' THEN
          EXECUTE IMMEDIATE 'ALTER PACKAGE ' || rec.object_name || ' COMPILE';
        ELSIF rec.object_type = 'PACKAGE BODY' THEN
          EXECUTE IMMEDIATE 'ALTER PACKAGE ' || rec.object_name || ' COMPILE BODY';
        ELSE
          EXECUTE IMMEDIATE 'ALTER ' || rec.object_type || ' '
                            || rec.object_name || ' COMPILE';
        END IF;
      EXCEPTION WHEN OTHERS THEN
        NULL; -- lo intenta de nuevo en la siguiente pasada
      END;
    END LOOP;
  END LOOP;
END;
/

PROMPT
PROMPT ============================================================
PROMPT  RESUMEN
PROMPT ============================================================

SELECT object_type, COUNT(*) AS total,
       SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) AS validos,
       SUM(CASE WHEN status <> 'VALID' THEN 1 ELSE 0 END) AS invalidos
  FROM user_objects
 GROUP BY object_type
 ORDER BY object_type;

SPOOL OFF
