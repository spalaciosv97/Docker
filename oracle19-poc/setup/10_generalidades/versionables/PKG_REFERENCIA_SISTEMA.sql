--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA_SISTEMA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA_SISTEMA" IS
---
--- Descripción: Funciones principales para el CRUD de la tabla "grl_referencia_sistema".
--- Autor: David Alejandro Ramos M.
--- Fecha: nov-2025
---
    ---------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_REFERENCIA_SISTEMA
    ---------------------------------------------------------
    PROCEDURE INSERT_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------------------
    -- Elimina la relación REFERENCIA-SISTEMA.
    ----------------------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------------------
    -- Elimina la relación REFERENCIA-SISTEMA.
    ----------------------------------------------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------------------------
    -- Entrega la lista de Referencias que tiene asignado un sistema dado su ID
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALLBYSISTEMA_REFERENCIA_SISTEMA (
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );
    ---------------------------------------------------------------------------------------
    -- Entrega la lista de sistemas que tienen asignado una referencia  dado su ID
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALLBYREFERENCIA_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );
    ---------------------------------------------------------------------------------------
    -- Entrega toda la informacion de la tabla GRL_REFERENCIA_SISTEMA
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALL_REFERENCIA_SISTEMA (
        p_cursor          OUT SYS_REFCURSOR
    );

END PKG_REFERENCIA_SISTEMA;

/
