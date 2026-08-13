--------------------------------------------------------
--  Ref Constraints for Table GRL_ESTRUCTURA
--------------------------------------------------------

  ALTER TABLE "GENERALIDADES"."GRL_ESTRUCTURA" ADD CONSTRAINT "GRL_ESTRUCTURA_TIPO_FK" FOREIGN KEY ("ID_TIPO")
	  REFERENCES "GENERALIDADES"."GRL_REFERENCIA_ITEM" ("ID_ITEM") ENABLE NOVALIDATE;
