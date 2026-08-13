--------------------------------------------------------
--  DDL for Package PKG_UTILIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_UTILIDADES" AS


    type tr_referencias is record (id_referencia        number,
                                   id_item              number,
                                   nombre_item          varchar2(4000),
                                   script_insert_ref    varchar2(4000),
                                   script_insert_item   varchar2(4000),
                                   script_vista         varchar2(4000),
                                   observaciones        varchar2(4000)                            
                                  );
       
    type tt_referencias is table of tr_referencias;

    PROCEDURE VALIDATE_PERSONA(
        p_idPersona     IN GENERALIDADES.GRL_PERSONA.ID_PERSONA%TYPE
    );

    PROCEDURE VALIDATE_ITEM(
        p_idPadre       IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_idItem        IN NUMBER
    );

    FUNCTION HANDLE_EXCEPTION(
        p_errorCode     IN NUMBER,
        p_errorMessage  IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION TO_FLOAT(
        p_value         IN VARCHAR2
    ) return NUMBER;


    FUNCTION creaReferencias(p_nombre varchar2, p_descripcion varchar2, p_items varchar2, p_rut_user number, p_nombre_vista varchar2 default null)return tt_referencias pipelined;
    
    /* =====================================================================
        FUNCTION : BUILD_ERROR_CURSOR
        Centraliza el manejo de errores que se repite en cada procedure:
        captura SQLCODE/SQLERRM, arma el JSON de contexto + backtrace,
        registra el log, y devuelve el cursor de error listo para abrir.

        USO (dentro del EXCEPTION de cualquier procedure):

          EXCEPTION
              WHEN OTHERS THEN
                  p_cursor := PKG_UTILIDADES.BUILD_ERROR_CURSOR(
                      p_idApp,
                      JSON_OBJECT(
                          'p_campo1' VALUE p_campo1,
                          'p_campo2' VALUE p_campo2
                          RETURNING CLOB)
                  );
          END MI_PROCEDURE;
    =======================================================================*/
    FUNCTION BUILD_ERROR_CURSOR(
        p_idApp    IN NUMBER,
        p_contexto IN CLOB
    ) RETURN SYS_REFCURSOR;
    
END PKG_UTILIDADES;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "CALIDAD";
