--------------------------------------------------------
--  DDL for Package PKG_GRL_ATRIBUTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ATRIBUTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_atributo
-- PURPOSE:    Package para las funciones CRUD de los atributos que se pueden asociar a las estructuras.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_atributo
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Atributo (
        p_id_componente     IN grl_atributo.id_componente%TYPE,
        p_nombre            IN grl_atributo.nombre%TYPE,
        p_id_tipo_dato      IN grl_atributo.id_tipo_dato%TYPE,
        p_largo             IN grl_atributo.largo%TYPE,
        p_posicion          IN grl_atributo.posicion%TYPE,
        p_id_estado         IN grl_atributo.id_estado%TYPE,
        p_objeto            IN grl_atributo.objeto%TYPE,
        p_id_columna        IN grl_atributo.columna_id%TYPE,
        p_columna_data      IN grl_atributo.columna_data%TYPE,
        p_obligatorio       IN grl_atributo.obligatorio%TYPE,
        p_valor_default     IN grl_atributo.valor_default%TYPE,
        p_mascara           IN grl_atributo.mascara%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_id_componente     IN grl_atributo.id_componente%TYPE,
        p_nombre            IN grl_atributo.nombre%TYPE,
        p_id_tipo_dato      IN grl_atributo.id_tipo_dato%TYPE,
        p_largo             IN grl_atributo.largo%TYPE,
        p_posicion          IN grl_atributo.posicion%TYPE,
        p_id_estado         IN grl_atributo.id_estado%TYPE,
        p_objeto            IN grl_atributo.objeto%TYPE,
        p_id_columna        IN grl_atributo.columna_id%TYPE,
        p_columna_data      IN grl_atributo.columna_data%TYPE,
        p_obligatorio       IN grl_atributo.obligatorio%TYPE,
        p_valor_default     IN grl_atributo.valor_default%TYPE,
        p_mascara           IN grl_atributo.mascara%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Atributo (
        p_id_atributo   IN grl_atributo.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetByComponente_Atributo (
        p_id_componente      IN grl_atributo.id_componente%TYPE,
        p_cursor             OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


PROCEDURE GetAll_Atributo (
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
