--------------------------------------------------------
--  DDL for Trigger TRGG_ARCHIVO_VERSION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "GENERALIDADES"."TRGG_ARCHIVO_VERSION" 
BEFORE INSERT ON GRL_ARCHIVO_VERSION
FOR EACH ROW
BEGIN
    IF :NEW.id_version IS NULL THEN
        SELECT SEC_ARCHIVOS_ID_VERSION.NEXTVAL
        INTO :NEW.id_version
        FROM dual;
    END IF;
END;
/
ALTER TRIGGER "GENERALIDADES"."TRGG_ARCHIVO_VERSION" ENABLE;