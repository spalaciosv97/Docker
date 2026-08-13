--------------------------------------------------------
--  DDL for Package PKG_ESTRUCTURA_NEGOCIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_ESTRUCTURA_NEGOCIO" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_estructura_negocio
-- PURPOSE:    Package para las funciones de negocio el manejo de estructuras
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herquiñigo   1. Package para la funciones de negocio de las estructuras
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Propaga_atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    );

PROCEDURE Mover_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_id_padre_nuevo    IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    );

PROCEDURE Get_datos_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    );


PROCEDURE Get_estructura(
        p_id_estructura      IN grl_estructura.id_estructura%TYPE,
        p_cursor             OUT SYS_REFCURSOR 
    );

PROCEDURE Get_componentes_hijos (
        p_id_elemento          IN grl_elemento.id_item%TYPE,
        p_cursor               OUT SYS_REFCURSOR  
    );

PROCEDURE Get_arbol_elementos (
        p_id_estructura        IN grl_estructura.id_estructura%TYPE,
        p_cursor               OUT SYS_REFCURSOR  
    );

PROCEDURE Get_objeto_lista (
        p_cursor               OUT SYS_REFCURSOR  
    );

PROCEDURE Get_objeto_columnas (
        p_objeto               IN  VARCHAR2,
        p_cursor               OUT SYS_REFCURSOR  
    );

PROCEDURE Get_lista (
        p_id_atributo          IN  NUMBER,
        p_cursor               OUT SYS_REFCURSOR  
    );

end ;

/
