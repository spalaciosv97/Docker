--------------------------------------------------------
--  DDL for Package PKG_GRL_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ELEMENTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento
-- PURPOSE:    Package para las funciones CRUD de elementos que conforman una estruturas, es decir, la data.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_elemento
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Elemento (
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Elemento (
        p_id_item       IN grl_elemento.id_item%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


END;

/
