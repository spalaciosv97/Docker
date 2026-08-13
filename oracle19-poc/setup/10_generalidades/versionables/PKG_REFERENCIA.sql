--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA" IS    
---
--- Descripción: Funciones principales para el CRUD de la tabla "grl_referencia".
--- Autor: DTIC.
--- Fecha: oct-2025
---     
    --------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_REFERENCIA
    --------------------------------------------------------
    PROCEDURE INSERT_REFERENCIA (
        p_nombre            IN GRL_REFERENCIA.NOMBRE%TYPE,
        p_descripcion       IN GRL_REFERENCIA.DESCRIPCION%TYPE,
        p_idTipo            IN GRL_REFERENCIA.ID_TIPO%TYPE,
        p_idClase           IN GRL_REFERENCIA.ID_CLASE%TYPE,
        p_idEstado          IN GRL_REFERENCIA.ID_ESTADO%TYPE,
        p_userReg           IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    --------------------------------------------------------------------
    -- Actualiza los datos de una referencia en la tabla GRL_REFERENCIA
    --------------------------------------------------------------------
    PROCEDURE UPDATE_REFERENCIA (
        p_idReferencia      IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_nombre            IN GRL_REFERENCIA.NOMBRE%TYPE,
        p_descripcion       IN GRL_REFERENCIA.DESCRIPCION%TYPE,
        p_idTipo            IN GRL_REFERENCIA.ID_TIPO%TYPE,
        p_idClase           IN GRL_REFERENCIA.ID_CLASE%TYPE,
        p_idEstado          IN GRL_REFERENCIA.ID_ESTADO%TYPE,
        p_userReg           IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------
    -- Cambia el estado de una referencia de la tabla GRL_REFERENCIA
    ----------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIA (
        p_idReferencia      IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_userReg           IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
    
    ----------------------------------------------------------------
    -- Elimina una referencia de la tabla GRL_REFERENCIA
    ----------------------------------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIA (
        p_idReferencia      IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_userReg           IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    ----------------------------------------------------
    -- Entrega todos los datos del parámetro dado su ID
    ----------------------------------------------------
    PROCEDURE GETBYID_REFERENCIA (
        p_idReferencia      IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
    
    ---------------------------------------------------------------------
    -- Entrega todos los datos de todos las referencias registrados
    ---------------------------------------------------------------------
    PROCEDURE GETALL_REFERENCIA (
        p_cursor            OUT SYS_REFCURSOR
    );

END PKG_REFERENCIA;

/
