--------------------------------------------------------
--  DDL for Package PKG_GRL_DATO_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_DATO_ELEMENTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_dato_elemento
-- PURPOSE:    Package para las funciones CRUD de los datos de los atributos de un elementos.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_dato_elemento
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Datos (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Dato (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR 
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

PROCEDURE GetById_Dato (
        p_id_item       IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo   IN grl_dato_elemento.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

PROCEDURE GetAll_Dato (
        p_id_item          IN grl_dato_elemento.id_item%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    );

END;

/
