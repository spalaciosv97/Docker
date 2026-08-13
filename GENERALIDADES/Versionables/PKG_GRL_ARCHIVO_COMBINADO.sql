--------------------------------------------------------
--  DDL for Package PKG_GRL_ARCHIVO_COMBINADO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ARCHIVO_COMBINADO" AS

      PROCEDURE PROC_LISTAR_ARCHIVOS_CON_VERSIONES(
        p_cursor OUT SYS_REFCURSOR
      );

    PROCEDURE PROC_OBTENER_ARCHIVO_Y_VERSION(
        p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_proyecto  IN GRL_ARCHIVO.APP%TYPE,
        p_cursor    OUT SYS_REFCURSOR
    );

      PROCEDURE proc_delete_archivo_completo(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_cursor     OUT SYS_REFCURSOR
      );

    PROCEDURE PROC_REPORTE_ESPACIO_POR_APP(
        p_app            IN GRL_ARCHIVO.APP%TYPE             DEFAULT NULL,
        p_estadoArchivo  IN GRL_ARCHIVO.ESTADO%TYPE          DEFAULT '1',
        p_estadoVersion  IN GRL_ARCHIVO_VERSION.ESTADO%TYPE  DEFAULT NULL,
        p_cursor         OUT SYS_REFCURSOR
    );

      PROCEDURE PROC_ULTIMA_VERSION_ACTIVA_ALL(
        p_cursor   OUT SYS_REFCURSOR
      );

      PROCEDURE PROC_ULTIMA_VERSION_ACTIVA(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_proyecto   IN GRL_ARCHIVO.app%TYPE,
        p_cursor     OUT SYS_REFCURSOR
      );

    PROCEDURE PROC_REPORTE_VERSIONES_POR_ARCHIVO(
        p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor    OUT SYS_REFCURSOR
    );

      PROCEDURE PROC_ARCHIVO_MULT_VERSIONES(
        p_proyecto IN GRL_ARCHIVO.app%TYPE,
        p_cursor   OUT SYS_REFCURSOR
      );

    PROCEDURE PROC_REPORTE_LIMPIEZA_SUGERIDA(
        p_app            IN GRL_ARCHIVO.APP%TYPE             DEFAULT NULL,
        p_diasInactivo   IN NUMBER                           DEFAULT 365,
        p_estadoArchivo  IN GRL_ARCHIVO.ESTADO%TYPE          DEFAULT NULL,
        p_estadoVersion  IN GRL_ARCHIVO_VERSION.ESTADO%TYPE  DEFAULT NULL,
        p_cursor         OUT SYS_REFCURSOR
    );
    PROCEDURE PROC_REPORTE_ACTIVIDAD_USUARIOS(
        p_app     IN GRL_ARCHIVO.APP%TYPE DEFAULT NULL,
        p_topN    IN NUMBER DEFAULT 10,
        p_cursor  OUT SYS_REFCURSOR
    );
    PROCEDURE PROC_REPORTE_EVOLUCION_MENSUAL(
        p_app          IN  GRL_ARCHIVO.APP%TYPE DEFAULT NULL,
        p_fechaInicio  IN  DATE                 DEFAULT NULL,
        p_fechaFin     IN  DATE                 DEFAULT NULL,
        p_cursor       OUT SYS_REFCURSOR
    );

    PROCEDURE INFO_FILE_FOR_DELETE(
        p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor       OUT SYS_REFCURSOR
    );

    PROCEDURE FILE_DELETE_MASTER(
        p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor       OUT SYS_REFCURSOR
    );
END PKG_GRL_ARCHIVO_COMBINADO;

/
