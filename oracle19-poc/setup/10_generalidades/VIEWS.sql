--------------------------------------------------------
--  DDL for View GRL_ESTADO_ATRIBUTO_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_ESTADO_ATRIBUTO_VW" ("ID_ITEM", "ESTADO_ATRIBUTO") AS 
  SELECT c.id_item, c.nombre estado_atributo
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 51
;
--------------------------------------------------------
--  DDL for View GRL_ESTADO_ESTRUCTURA_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_ESTADO_ESTRUCTURA_VW" ("ID_ITEM", "ESTADO_ESTRUCTURA") AS 
  SELECT c.id_item, c.nombre estado_estructura
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 50
;
--------------------------------------------------------
--  DDL for View GRL_ESTADO_ITEM_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_ESTADO_ITEM_VW" ("ID_ESTADO_ITEM", "ESTADO_ITEM") AS 
  SELECT c.id_item id_estado_item, c.nombre estado_item
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 16
;
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_ESTADO_ITEM_VW" TO "APPSTK";
--------------------------------------------------------
--  DDL for View GRL_GENEROS_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_GENEROS_VW" ("ID_GENERO", "GENERO") AS 
  SELECT c.id_item id_genero, c.nombre genero
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 22
;
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "APPSTK";
  GRANT SELECT ON "GENERALIDADES"."GRL_GENEROS_VW" TO "SIACPAAPPS";
--------------------------------------------------------
--  DDL for View GRL_OBJETO_LISTA_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_OBJETO_LISTA_VW" ("ID_ITEM", "OBJETO", "ALIAS") AS 
  select id_item, nombre as objeto, replace(replace(valor_ext,'[',''),']') alias
from grl_referencia_item 
where id_estado = 125 and id_referencia = 1410
;
--------------------------------------------------------
--  DDL for View GRL_PAISES_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_PAISES_VW" ("ID_PAIS", "PAIS", "NOMBRE_INGLES", "CODIGO_2", "CODIGO_3", "CODIGO_NUM") AS 
  SELECT c.id_item id_pais, c.nombre pais, upper(REGEXP_SUBSTR(valor_ext, '''([^'']*)''', 1, 1, NULL, 1)) AS nombre_ingles,
    REGEXP_SUBSTR(valor_ext, '''([^'']*)''', 1, 2, NULL, 1) AS codigo_2,
    REGEXP_SUBSTR(valor_ext, '''([^'']*)''', 1, 3, NULL, 1) AS codigo_3,
    REGEXP_SUBSTR(valor_ext, '''([^'']*)''', 1, 4, NULL, 1) AS codigo_num
from grl_referencia_item c
where valor_ext is not null and c.id_estado = 125 and c.id_referencia = 24
;
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "APPSTK";
  GRANT SELECT ON "GENERALIDADES"."GRL_PAISES_VW" TO "SIACPAAPPS";
--------------------------------------------------------
--  DDL for View GRL_REGIONES_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_REGIONES_VW" ("ID_REGION", "ID_GOB_REGION", "REGION", "ID_PROVINCIA", "ID_GOB_PROVINCIA", "PROVINCIA", "ID_COMUNA", "ID_GOB_COMUNA", "COMUNA") AS 
  select r.id_item id_region, r.valor_ext id_gob_region, r.nombre region, 
       p.id_item id_provincia, p.valor_ext id_gob_provincia, p.nombre provincia, 
       c.id_item id_comuna, c.valor_ext id_gob_comuna, c.nombre comuna
from grl_referencia_item r, grl_referencia_item p, grl_referencia_item c
where r.id_item = p.id_padre
and p.id_item = c.id_padre
and c.id_estado = 125 and c.nivel = 3 and c.id_referencia = 21
;
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "APPSTK";
  GRANT SELECT ON "GENERALIDADES"."GRL_REGIONES_VW" TO "SIACPAAPPS";
--------------------------------------------------------
--  DDL for View GRL_SEXOS_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_SEXOS_VW" ("ID_SEXO", "SEXO") AS 
  SELECT c.id_item id_sexo, c.nombre sexo
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 26
;
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "APPSTK";
  GRANT SELECT ON "GENERALIDADES"."GRL_SEXOS_VW" TO "SIACPAAPPS";
--------------------------------------------------------
--  DDL for View GRL_TIPO_NECESIDAD_ITEM_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_TIPO_NECESIDAD_ITEM_VW" ("ID_ITEM", "TIPO_NECESIDAD", "ID_PADRE") AS 
  SELECT c.id_item id_item, c.nombre tipo_necesidad, id_padre
from grl_referencia_item c
where id_padre is not null and c.id_estado = 125 and c.id_referencia = 284
;
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPO_NECESIDAD_ITEM_VW" TO "SIACPAAPPS";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPO_NECESIDAD_ITEM_VW" TO "SIACPATESTTIC";
--------------------------------------------------------
--  DDL for View GRL_TIPO_NECESIDAD_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_TIPO_NECESIDAD_VW" ("ID_ITEM", "TIPO_NECESIDAD") AS 
  SELECT c.id_item id_item, c.nombre tipo_necesidad 
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 284
;
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPO_NECESIDAD_VW" TO "SIACPAAPPS";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPO_NECESIDAD_VW" TO "SIACPATESTTIC";
--------------------------------------------------------
--  DDL for View GRL_TIPOS_DATOS_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_TIPOS_DATOS_VW" ("ID_TIPO_DATO", "TIPO_DATO") AS 
  SELECT c.id_item id_tipo_dato, c.nombre tipo_dato
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 13
;
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DATOS_VW" TO "APPSTK";
--------------------------------------------------------
--  DDL for View GRL_TIPOS_DIRECCION_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" ("ID_TIPO_DIRECCION", "TIPO_DIRECCION") AS 
  SELECT c.id_item id_tipo_direccion, c.nombre tipo_direccion
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 25
;
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_DIRECCION_VW" TO "APPSTK";
--------------------------------------------------------
--  DDL for View GRL_TIPOS_IDENTIFICADOR_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" ("ID_TIPO", "TIPO_IDENTIFICADOR") AS 
  SELECT c.id_item id_tipo, c.nombre tipo_identificador
from grl_referencia_item c
where c.id_estado = 125 and c.id_referencia = 23
;
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "APPGRL";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "AUDITOR";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "APPLOG";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "SIGESUSTIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "APPSSGU";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "SIREPER";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "APPSRP";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "SIGETIC";
  GRANT SELECT ON "GENERALIDADES"."GRL_TIPOS_IDENTIFICADOR_VW" TO "APPSTK";
