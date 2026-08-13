--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA_ITEM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA_ITEM" IS
---
--- Descripción: Funciones principales para el CRUD de la tabla "grl_parametro_item".
--- Autor: Jorge Rodríguez Salinas.
--- Fecha: oct-2025
--- 

    ------------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_PARAMETRO_ITEM
    ------------------------------------------------------------
    PROCEDURE INSERT_REFERENCIAITEM (
        p_idReferencia      IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nombre            IN GRL_REFERENCIA_ITEM.NOMBRE%TYPE,
        p_valorExt          IN GRL_REFERENCIA_ITEM.VALOR_EXT%TYPE,
        p_idTipoDato        IN GRL_REFERENCIA_ITEM.ID_TIPO_DATO%TYPE,
        p_nivel             IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_idPadre           IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_idEstado          IN GRL_REFERENCIA_ITEM.ID_ESTADO%TYPE,
        p_userReg           IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    -----------------------------------------------------------------------------
    -- Actualiza los datos de una referencia item en la tabla GRL_PARAMETRO_ITEM
    -----------------------------------------------------------------------------
    PROCEDURE UPDATE_REFERENCIAITEM (
        p_idItem            IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_idReferencia      IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nombre            IN GRL_REFERENCIA_ITEM.NOMBRE%TYPE,
        p_valorExt          IN GRL_REFERENCIA_ITEM.VALOR_EXT%TYPE,
        p_idTipoDato        IN GRL_REFERENCIA_ITEM.ID_TIPO_DATO%TYPE,
        p_nivel             IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_idPadre           IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_idEstado          IN GRL_REFERENCIA_ITEM.ID_ESTADO%TYPE,
        p_userReg           IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    --------------------------------------------------------------------------
    -- Cambia el estado de una referencia item de la tabla GRL_PARAMETRO_ITEM
    --------------------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIAITEM (
        p_idItem            IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_userReg           IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------
    -- Elimina una referencia item de la tabla GRL_PARAMETRO_ITEM
    ----------------------------------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIAITEM (
        p_idItem            IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_userReg           IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    ----------------------------------------------------
    -- Entrega todos los datos del parámetro dado su ID
    ----------------------------------------------------
    PROCEDURE GETBYID_REFERENCIAITEM (
        p_idItem            IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    PROCEDURE GETBYIDREF_REFERENCIAITEM (
        p_idReferencia      IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    PROCEDURE GETBYIDPADRE_REFERENCIAITEM (
        p_idPadre           IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    PROCEDURE GETBYNIVEL_REFERENCIAITEM (
        p_idReferencia      IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nivel             IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------
    -- Entrega todos los datos de todos las referencias item registrados
    ---------------------------------------------------------------------
    PROCEDURE GETALL_REFERENCIAITEM (
        p_cursor            OUT SYS_REFCURSOR
    );

    PROCEDURE GETALLESTADOS_REFERENCIAITEM (
        p_cursor            OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------------
    -- Obtiene nombre de un codigo especifico de "referencia item" | 05-03-2026
    --------------------------------------------------------------------------- 
    FUNCTION GETNOMBRE_REFERENCIAITEM (
        p_idItem            IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE
    ) return varchar2;

END PKG_REFERENCIA_ITEM;


/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "CALIDAD";
