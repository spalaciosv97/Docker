--------------------------------------------------------
--  DDL for Package PKG_VALIDACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_VALIDACIONES" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_validaciones 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        15/10/2025   @author         1. Package generico con diferentes procedimientos de validaciones
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

                      
FUNCTION tamanio_campo( 
                        p_texto     in varchar2 ,         
                        p_tamanio   in number
                       ) return boolean;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

FUNCTION es_numero( 
                    p_var     in varchar2                  
                  ) return boolean;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

FUNCTION es_fecha( 
                  p_fecha     in varchar2
                 ) return boolean;






END;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SIGESUSTIC";
