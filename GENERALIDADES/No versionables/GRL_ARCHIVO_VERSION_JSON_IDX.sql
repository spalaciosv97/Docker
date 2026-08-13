--------------------------------------------------------
--  DDL for Index GRL_ARCHIVO_VERSION_JSON_IDX
--------------------------------------------------------

  CREATE INDEX "GENERALIDADES"."GRL_ARCHIVO_VERSION_JSON_IDX" ON "GENERALIDADES"."GRL_ARCHIVO_VERSION" ("METADATA") 
   INDEXTYPE IS "CTXSYS"."CONTEXT_V2"  PARAMETERS ('SIMPLIFIED_JSON ')
