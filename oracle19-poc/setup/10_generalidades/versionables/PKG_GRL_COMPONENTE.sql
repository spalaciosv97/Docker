--------------------------------------------------------
--  DDL for Package PKG_GRL_COMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_COMPONENTE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_componente
-- PURPOSE:    Package para las funciones CRUD de los componentes de una estruturas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_componente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Componente (
        p_nombre            IN grl_componente.nombre%TYPE,
        p_descripcion       IN grl_componente.descripcion%TYPE,
        p_id_estructura     IN grl_componente.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Componente (
        p_id_Componente          IN grl_componente.id_Componente%TYPE,
        p_id_estructura     IN grl_componente.id_estructura%TYPE,
        p_nombre            IN grl_componente.nombre%TYPE,
        p_descripcion       IN grl_componente.descripcion%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Componente (
        p_id_Componente          IN grl_componente.id_Componente%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Componente (
        p_id_Componente      IN grl_componente.id_Componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetAll_Componente (
        v_id_estructura    IN grl_componente.id_estructura%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    );

END;

/
