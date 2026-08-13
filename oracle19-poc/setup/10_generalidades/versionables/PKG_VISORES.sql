--------------------------------------------------------
--  DDL for Package PKG_VISORES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_VISORES" AS 

    PROCEDURE GETALL_LOG_SYSTEM (
        p_param                 number,
        p_cursor                OUT SYS_REFCURSOR
    );
    
    PROCEDURE GETALL_AUDITOR (
        p_table                 VARCHAR2,
        p_fetch                 VARCHAR2,
        p_limit                 NUMBER DEFAULT 0,
        p_date                  TIMESTAMP DEFAULT NULL,
        p_cursor                OUT SYS_REFCURSOR
    );
    
    PROCEDURE GETSTATS_LOG_SYSTEM(
        p_cursor                OUT SYS_REFCURSOR
    ) ;

END PKG_VISORES;

/
