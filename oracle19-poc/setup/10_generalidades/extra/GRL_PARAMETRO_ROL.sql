--------------------------------------------------------
--  DDL for Table GRL_PARAMETRO_ROL
--
--  NO venia en la entrega de QA. Reconstruida desde el diccionario de
--  Desarrollo (ALL_TAB_COLUMNS + ALL_CONSTRAINTS).
--
--  Es referenciada por los package bodies.
--
--  Nota: en Desarrollo esta tabla NO tiene PRIMARY KEY ni FOREIGN KEY.
--  Sus 4 constraints son todos de tipo C (NOT NULL). Se replica tal
--  cual a proposito: agregarle una PK "obvia" sobre
--  (ID_PARAMETRO, ID_ROL) podria rechazar filas que el codigo si
--  inserta.
--------------------------------------------------------

  CREATE TABLE "GENERALIDADES"."GRL_PARAMETRO_ROL"
   (    "ID_PARAMETRO" NUMBER NOT NULL ENABLE,
        "ID_ROL" NUMBER NOT NULL ENABLE,
        "FECHA_REG" DATE DEFAULT SYSDATE NOT NULL ENABLE,
        "USER_REG" NUMBER NOT NULL ENABLE
   ) SEGMENT CREATION IMMEDIATE
  TABLESPACE "GENERALIDADES_DATA" ;
