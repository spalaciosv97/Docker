--------------------------------------------------------
--  DDL for Package PKG_GRL_ESTRUCTURA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ESTRUCTURA" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_estructura
-- PURPOSE:    Package para las funciones CRUD de las estruturas definidas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_estructura
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Estructura (
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetAll_Estructuras (
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
