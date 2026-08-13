--------------------------------------------------------
--  DDL for Package PKG_PARAMETRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_PARAMETRO" IS
---
--- Descripción: Funciones principales para el CRUD de la tabal "grl_parametro".
--- Autor: Juan Carlos Herquiñigo B.
--- Fecha: sep-2025
--- 
    ---------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_PARAMETRO
    ---------------------------------------------------------
    PROCEDURE INSERT_PARAMETRO (
        p_idSistemaParametro    IN GRL_PARAMETRO.ID_SISTEMA%TYPE,
        p_idModuloParametro     IN GRL_PARAMETRO.ID_MODULO%TYPE,
        p_idAplicacionParametro IN GRL_PARAMETRO.ID_APLICACION%TYPE,
        p_nombreParametro       IN GRL_PARAMETRO.NOMBRE%TYPE,
        p_descripcionParametro  IN GRL_PARAMETRO.DESCRIPCION%TYPE,
        p_valorParametro        IN GRL_PARAMETRO.VALOR%TYPE,
        p_idTipoParametro       IN GRL_PARAMETRO.ID_TIPO%TYPE,
        p_idEstadoParametro     IN GRL_PARAMETRO.ID_ESTADO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_idTipoDatoParametro   IN GRL_PARAMETRO.ID_TIPO_DATO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------
    -- Actualiza los datos de un parámetro.
    ----------------------------------------
    PROCEDURE UPDATE_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idSistemaParametro    IN GRL_PARAMETRO.ID_SISTEMA%TYPE,
        p_idModuloParametro     IN GRL_PARAMETRO.ID_MODULO%TYPE,
        p_idAplicacionParametro IN GRL_PARAMETRO.ID_APLICACION%TYPE,
        p_nombreParametro       IN GRL_PARAMETRO.NOMBRE%TYPE,
        p_descripcionParametro  IN GRL_PARAMETRO.DESCRIPCION%TYPE,
        p_valorParametro        IN GRL_PARAMETRO.VALOR%TYPE,
        p_idTipoParametro       IN GRL_PARAMETRO.ID_TIPO%TYPE,
        p_idEstadoParametro     IN GRL_PARAMETRO.ID_ESTADO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_idTipoDatoParametro   IN GRL_PARAMETRO.ID_TIPO_DATO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    --------------------------------------------------------------
    -- Cambia el estado de un parámetro de la tabla GRL_PARAMETRO
    --------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    --------------------------------------------------
    -- Elimina un parámetro de la tabla GRL_PARAMETRO
    --------------------------------------------------
    PROCEDURE DELETE_FISICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------------------
    -- Entrega todos los datos del parámetro dado su ID
    ----------------------------------------------------
    PROCEDURE GETBYID_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------------------------
    -- Entrega todos los datos de todos los parámetro registrados independiente del estado.
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALL_PARAMETRO (
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

END PKG_PARAMETRO;

/
