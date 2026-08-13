--------------------------------------------------------
--  DDL for Type T_ERRORS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "GENERALIDADES"."T_ERRORS" AS TABLE OF VARCHAR2(500); 

/
--------------------------------------------------------
--  DDL for Type T_RULE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "GENERALIDADES"."T_RULE" FORCE AS OBJECT (
    p_name         VARCHAR2(200),
    p_value_str    VARCHAR2(32767),
    p_value_num    NUMBER,
    p_value_date   DATE,
    p_value_clob   CLOB,
    p_rules        VARCHAR2(4000),
    p_cmp_date_lo  DATE,  
    p_cmp_date_hi  DATE
);

/

  GRANT EXECUTE ON "GENERALIDADES"."T_RULE" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULE" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULE" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULE" TO "DACIDTIC";
--------------------------------------------------------
--  DDL for Type T_RULES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "GENERALIDADES"."T_RULES" AS TABLE OF GENERALIDADES.T_RULE;

/

  GRANT EXECUTE ON "GENERALIDADES"."T_RULES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULES" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULES" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULES" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."T_RULES" TO "CALIDAD";
