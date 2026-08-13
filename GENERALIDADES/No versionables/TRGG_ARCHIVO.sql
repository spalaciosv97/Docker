--------------------------------------------------------
--  DDL for Trigger TRGG_ARCHIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "GENERALIDADES"."TRGG_ARCHIVO" 
    BEFORE INSERT
    ON GRL_ARCHIVO
    FOR EACH ROW
BEGIN
    IF :NEW.id_archivo IS NULL THEN
        SELECT SEC_ARCHIVOS_ID_ARCHIVO.NEXTVAL
        INTO :NEW.id_archivo
        FROM dual;
    END IF;
END;
ALTER TRIGGER "GENERALIDADES"."TRGG_ARCHIVO" ENABLE
