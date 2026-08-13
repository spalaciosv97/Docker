--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA_ROL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA_ROL" AS 
---
--- Descripción: Funciones principales para el CRUD de la tabla "GRL_REFERENCIA_ROL".
--- Autor: Jorge Rodríguez Salinas.
--- Fecha: nov-2025
--- 
    ------------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_REFERENCIA_ROL
    ------------------------------------------------------------
    PROCEDURE INSERT_REFERENCIA_ROL (
        p_idReferencia          IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_idRol                 IN GRL_REFERENCIA_ROL.ID_ROL%TYPE,
        p_userReg               IN GRL_REFERENCIA_ROL.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------------------------------
    -- Elimina una referencia item, se debe haber validado las referencias o dará exception
    ----------------------------------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIA_ROL (
        p_idReferencia          IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_idRol                 IN GRL_REFERENCIA_ROL.ID_ROL%TYPE,
        p_userReg               IN GRL_REFERENCIA_ROL.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------------------------------
    -- Elimina una referencia item, se debe haber validado las referencias o dará exception
    ----------------------------------------------------------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIA_ROL (
        p_idReferencia          IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_idRol                 IN GRL_REFERENCIA_ROL.ID_ROL%TYPE,
        p_userReg               IN GRL_REFERENCIA_ROL.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------------------
    -- Entrega todos los datos del parámetro dado su ID
    ----------------------------------------------------
    PROCEDURE GETBYID_REFERENCIA_ROL (
        p_idReferencia          IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    PROCEDURE GETBYIDROL_REFERENCIA_ROL (
        p_idRol                 IN GRL_REFERENCIA_ROL.ID_ROL%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------
    -- Entrega todos los datos de todos las referencias item registrados
    ---------------------------------------------------------------------
    PROCEDURE GETALL_REFERENCIA_ROL (
        p_cursor                OUT SYS_REFCURSOR
    );

END PKG_REFERENCIA_ROL;


/
