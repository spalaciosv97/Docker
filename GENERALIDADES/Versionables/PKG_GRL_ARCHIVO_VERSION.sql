--------------------------------------------------------
--  DDL for Package PKG_GRL_ARCHIVO_VERSION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ARCHIVO_VERSION" AS 

    PROCEDURE PROC_INSERT_VERSION(
        p_id_archivo IN GRL_ARCHIVO_VERSION.id_archivo%TYPE,
        p_estado IN GRL_ARCHIVO_VERSION.estado%TYPE DEFAULT '0',
        p_metadata IN CLOB,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_UPDATE_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_estado IN GRL_ARCHIVO_VERSION.estado%TYPE,
        p_metadata IN CLOB,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_DELETE_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_SELECT_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PROC_LIST_VERSIONES(
        p_cursor OUT SYS_REFCURSOR
    );
-- debo analizar mejor esta opcion no se que pensaba en el momento que lo hice 
    PROCEDURE proc_delete_archivo_version_V2(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE proc_delete_update_masivo(
        p_id_archivo IN GRL_ARCHIVO_VERSION.id_archivo%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE proc_activar_archivo (
     p_id_archivo IN GRL_ARCHIVO_VERSION.id_archivo%TYPE,
     p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
     p_cursor OUT SYS_REFCURSOR
    );

PROCEDURE PROC_DELETE_VERSION_IDARCHIVO(
        p_id_archivo IN GRL_ARCHIVO_VERSION.ID_ARCHIVO%TYPE,
        p_cursor OUT SYS_REFCURSOR
    );


END PKG_GRL_ARCHIVO_VERSION;

/
