--------------------------------------------------------
--  DDL for Package PKG_GRL_ELEMENTO_PADRE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ELEMENTO_PADRE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento_padre
-- PURPOSE:    Package para las funciones CRUD de las relaciones de un elemento con uno o más padres
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        4/07/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_elemento_padre
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Get_padres (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_cursor             OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Get_hijos (
        p_id_padre      IN grl_elemento_padre.id_padre%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) ;

END;

/
