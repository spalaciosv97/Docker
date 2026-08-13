--------------------------------------------------------
--  DDL for Package PKG_GRL_ARCHIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ARCHIVO" AS 

    PROCEDURE PROC_INSERT_ARCHIVO(
        p_nombre       IN GRL_ARCHIVO.NOMBRE%TYPE,
        p_alias        IN GRL_ARCHIVO.ALIAS%TYPE,
        p_ruta         IN GRL_ARCHIVO.RUTA%TYPE,
        p_estado       IN GRL_ARCHIVO.ESTADO%TYPE DEFAULT '1',
        p_app          IN GRL_ARCHIVO.APP%TYPE,
        p_usuario      IN GRL_ARCHIVO.USUARIO%TYPE,
        p_cursor       OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_UPDATE_ARCHIVO(
        p_id_archivo   IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_nombre       IN GRL_ARCHIVO.NOMBRE%TYPE,
        p_alias        IN GRL_ARCHIVO.ALIAS%TYPE,
        p_estado       IN GRL_ARCHIVO.ESTADO%TYPE,
        p_app          IN GRL_ARCHIVO.APP%TYPE,
        p_usuario      IN GRL_ARCHIVO.USUARIO%TYPE,
        p_cursor       OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_DELETE_ARCHIVO(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor     OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_SELECT_ARCHIVO(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_proyecto  IN GRL_ARCHIVO.APP%TYPE,
        p_cursor    OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_LIST_ARCHIVOS(
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE proc_delete_archivo_v2(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_DELETE_HIJOS_EXTERNOS(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor     OUT SYS_REFCURSOR
    );

END PKG_GRL_ARCHIVO;

/
