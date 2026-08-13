-- =====================================================================
-- recompile.sql — Recompilacion final, DESPUES de los sinonimos
--
-- POR QUE EXISTE ESTE PASO
--
-- Varios package bodies de GENERALIDADES no llaman a los packages por
-- su nombre real, sino a traves de los SINONIMOS PUBLICOS:
--
--     PKG_UTILIDADES  ->  CONST.REF_ITEM_ESTADO_ACTIVO
--                         CONST.LOG_ERROR
--     PKG_VALIDATOR   ->  UTILIDADES.VALIDATE_PERSONA
--                         CONST.ERROR_VALIDATOR
--
-- donde CONST = PKG_GRL_CONFIG y UTILIDADES = PKG_UTILIDADES.
--
-- Pero CREATE PUBLIC SYNONYM requiere SYS, asi que los sinonimos se
-- crean en 20_post, despues del MASTER. Resultado: cuando el MASTER
-- compila los bodies, esos identificadores todavia no existen y 19 de
-- los 22 quedan INVALID con PLS-00201 / ORA-00904.
--
-- El bucle de recompilacion que trae el MASTER no alcanza: corre antes
-- de que existan los sinonimos.
--
-- Esto NO se ve si se reinstala sobre una base donde ya se corrio
-- antes, porque los sinonimos publicos sobreviven al DROP USER. Solo
-- aparece en una instalacion desde cero.
--
-- Ejecutar como SYS/SYSTEM.
-- =====================================================================

ALTER SESSION SET CONTAINER = DEMOPDB;

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SPOOL /poc/logs/recompile.log

PROMPT
PROMPT === Invalidos ANTES de recompilar ===================================
SELECT COUNT(*) AS invalidos FROM dba_objects
 WHERE owner = 'GENERALIDADES' AND status <> 'VALID';

BEGIN
  -- Hasta 5 pasadas: los bodies dependen unos de otros, asi que cada
  -- pasada desbloquea la siguiente.
  FOR i IN 1 .. 5 LOOP
    FOR rec IN (
      SELECT object_name, object_type
        FROM dba_objects
       WHERE owner = 'GENERALIDADES'
         AND object_type IN ('PACKAGE','PACKAGE BODY','VIEW','TRIGGER',
                             'FUNCTION','PROCEDURE','TYPE')
         AND status = 'INVALID'
    ) LOOP
      BEGIN
        IF rec.object_type = 'PACKAGE' THEN
          EXECUTE IMMEDIATE 'ALTER PACKAGE GENERALIDADES.'
                            || rec.object_name || ' COMPILE';
        ELSIF rec.object_type = 'PACKAGE BODY' THEN
          EXECUTE IMMEDIATE 'ALTER PACKAGE GENERALIDADES.'
                            || rec.object_name || ' COMPILE BODY';
        ELSE
          EXECUTE IMMEDIATE 'ALTER ' || rec.object_type
                            || ' GENERALIDADES.' || rec.object_name
                            || ' COMPILE';
        END IF;
      EXCEPTION WHEN OTHERS THEN
        NULL; -- se reintenta en la pasada siguiente
      END;
    END LOOP;
  END LOOP;
END;
/

-- Red de seguridad por si quedara algo suelto.
BEGIN
  UTL_RECOMP.RECOMP_SERIAL('GENERALIDADES');
END;
/

PROMPT
PROMPT === Invalidos DESPUES de recompilar (debe ser 0) ====================
SELECT COUNT(*) AS invalidos FROM dba_objects
 WHERE owner = 'GENERALIDADES' AND status <> 'VALID';

SPOOL OFF
