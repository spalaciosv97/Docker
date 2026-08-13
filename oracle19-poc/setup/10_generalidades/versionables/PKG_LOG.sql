--------------------------------------------------------
--  DDL for Package PKG_LOG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_LOG" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_log 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        02/10/2025   jmaizares         1. Package para la manipulacion de los registros de la tabla log_system 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE REGISTRA_LOG(          
                        p_app_id   in auditor.log_system.app_id%type default null, 
                        p_tipo     in auditor.log_system.tipo%type default null, 
                        p_log_json in auditor.log_system.log_json%type,
                        p_titulo   in auditor.log_system.titulo%type default null, 
                        p_origen   in auditor.log_system.origen%type default null
                      );                      
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE REGISTRA_LOG(          
                        p_app_id   in  auditor.log_system.app_id%type default null, 
                        p_tipo     in  auditor.log_system.tipo%type default null, 
                        p_log_json in  auditor.log_system.log_json%type,
                        p_log_id   out number                        
                      );

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE INSERT_REGISTRO(p_log_id   in auditor.log_system.log_id%type,
                          p_app_id   in auditor.log_system.app_id%type,                            
                          p_log_json in auditor.log_system.log_json%type,
                          p_tipo     in auditor.log_system.tipo%type default null,
                          p_titulo   in auditor.log_system.titulo%type default null,
                          p_origen   in auditor.log_system.origen%type default null                          
                         );
                         
FUNCTION GENERA_LOG_ID RETURN NUMBER;
END;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "CALIDAD";
