--------------------------------------------------------
--  DDL for Trigger INSERT_ID_DIRECCION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "GENERALIDADES"."INSERT_ID_DIRECCION" 
   before insert on GRL_DIRECCION 
   for each row 
begin  
   if inserting then 
      if :NEW.ID_DIRECCION is null then 
         select GRL_DIRECCIONES_SEQ.nextval into :NEW.ID_DIRECCION from dual; 
      end if; 
   end if; 
end;



/
ALTER TRIGGER "GENERALIDADES"."INSERT_ID_DIRECCION" ENABLE;