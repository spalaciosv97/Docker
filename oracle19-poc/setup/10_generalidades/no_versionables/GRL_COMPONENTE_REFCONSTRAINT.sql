--------------------------------------------------------
--  Ref Constraints for Table GRL_COMPONENTE
--------------------------------------------------------

  ALTER TABLE "GENERALIDADES"."GRL_COMPONENTE" ADD CONSTRAINT "GRL_COMPONENTE_ESTRUCTURA_FK" FOREIGN KEY ("ID_ESTRUCTURA")
	  REFERENCES "GENERALIDADES"."GRL_ESTRUCTURA" ("ID_ESTRUCTURA") ENABLE NOVALIDATE;
