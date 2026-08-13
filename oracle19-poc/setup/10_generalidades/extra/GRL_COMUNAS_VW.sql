--------------------------------------------------------
--  DDL for View GRL_COMUNAS_VW
--
--  NO venia en VIEWS.sql. Obtenida desde ALL_VIEWS.TEXT_VC en
--  Desarrollo. Es referenciada por los package bodies.
--
--  Sigue el mismo patron que las otras 12 vistas: una proyeccion
--  filtrada de GRL_REFERENCIA_ITEM. Depende de que existan los datos
--  con ID_REFERENCIA = 21 e ID_ESTADO = 125, que vienen en 30_data.
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "GENERALIDADES"."GRL_COMUNAS_VW"
    ("ID_COMUNA", "ID_GOB_COMUNA", "COMUNA") AS
  SELECT c.id_item    AS id_comuna,
         c.valor_ext  AS id_gob_comuna,
         c.nombre     AS comuna
    FROM grl_referencia_item c
   WHERE c.id_estado = 125
     AND c.nivel = 3
     AND c.id_referencia = 21;
