--------------------------------------------------------
--  DDL for Package PKG_GRL_SUBCOMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_SUBCOMPONENTE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_subcomponente
-- PURPOSE:    Package para las funciones CRUD de las relaciones entre componentes de una estructuras
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herquiñigo   1. Package para la manipulacion de los registros de la tabla grl_subcomponente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_subcomponente (
        p_id_componente      IN grl_subcomponente.id_componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
