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
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la funciones de negocio de las estructuras
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
--------------------------------------------------------
--  DDL for Package PKG_GRL_ATRIBUTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ATRIBUTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_atributo
-- PURPOSE:    Package para las funciones CRUD de los atributos que se pueden asociar a las estructuras.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_atributo
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Atributo (
        p_id_componente     IN grl_atributo.id_componente%TYPE,
        p_nombre            IN grl_atributo.nombre%TYPE,
        p_id_tipo_dato      IN grl_atributo.id_tipo_dato%TYPE,
        p_largo             IN grl_atributo.largo%TYPE,
        p_posicion          IN grl_atributo.posicion%TYPE,
        p_id_estado         IN grl_atributo.id_estado%TYPE,
        p_objeto            IN grl_atributo.objeto%TYPE,
        p_id_columna        IN grl_atributo.columna_id%TYPE,
        p_columna_data      IN grl_atributo.columna_data%TYPE,
        p_obligatorio       IN grl_atributo.obligatorio%TYPE,
        p_valor_default     IN grl_atributo.valor_default%TYPE,
        p_mascara           IN grl_atributo.mascara%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_id_componente     IN grl_atributo.id_componente%TYPE,
        p_nombre            IN grl_atributo.nombre%TYPE,
        p_id_tipo_dato      IN grl_atributo.id_tipo_dato%TYPE,
        p_largo             IN grl_atributo.largo%TYPE,
        p_posicion          IN grl_atributo.posicion%TYPE,
        p_id_estado         IN grl_atributo.id_estado%TYPE,
        p_objeto            IN grl_atributo.objeto%TYPE,
        p_id_columna        IN grl_atributo.columna_id%TYPE,
        p_columna_data      IN grl_atributo.columna_data%TYPE,
        p_obligatorio       IN grl_atributo.obligatorio%TYPE,
        p_valor_default     IN grl_atributo.valor_default%TYPE,
        p_mascara           IN grl_atributo.mascara%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Atributo (
        p_id_atributo   IN grl_atributo.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetByComponente_Atributo (
        p_id_componente      IN grl_atributo.id_componente%TYPE,
        p_cursor             OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


PROCEDURE GetAll_Atributo (
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_COMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_COMPONENTE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_componente
-- PURPOSE:    Package para las funciones CRUD de los componentes de una estruturas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_componente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Componente (
        p_nombre            IN grl_componente.nombre%TYPE,
        p_descripcion       IN grl_componente.descripcion%TYPE,
        p_id_estructura     IN grl_componente.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Componente (
        p_id_Componente          IN grl_componente.id_Componente%TYPE,
        p_id_estructura     IN grl_componente.id_estructura%TYPE,
        p_nombre            IN grl_componente.nombre%TYPE,
        p_descripcion       IN grl_componente.descripcion%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Componente (
        p_id_Componente          IN grl_componente.id_Componente%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Componente (
        p_id_Componente      IN grl_componente.id_Componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetAll_Componente (
        v_id_estructura    IN grl_componente.id_estructura%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    );

END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_CONFIG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_CONFIG" AS

  /*
   * PKG_GRL_CONFIG � Paquete de configuraci�n global del sistema SGU
   * ---------------------------------------------------------------
   * Centraliza las constantes de referencia e �tems del sistema con
   * el objetivo de evitar consultas innecesarias a la base de datos
   * y garantizar consistencia en los procedimientos almacenados (PL).
   *
   * Autor  : Brahyant Mill�n
   * 
   */
  ------------------------------------------------------------------------------
  -- CODIGO DE APP
  -- Se utiliza en el package  para registrar los logs.
  ------------------------------------------------------------------------------ 
  APP_SGU                            CONSTANT NUMBER := 004;
  APP_CGA                            CONSTANT NUMBER := 005;
  APP_SIGAC                          CONSTANT NUMBER := 006;
  APP_SACPF                          CONSTANT NUMBER := 007;
  APP_GDO                            CONSTANT NUMBER := 008;
  APP_SGR                            CONSTANT NUMBER := 775;
  ------------------------------------------------------------------------------
  -- REFERENCIAS DE PADRE
  ------------------------------------------------------------------------------
  SGU_REFERENCIA_PADRE          	 CONSTANT NUMBER := 383;
  ------------------------------------------------------------------------------
  -- ESTADOS DE USUARIO
  -- Referencia y estados del ciclo de vida de un usuario.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_USUARIOS         CONSTANT NUMBER := 2126;
  SGU_ITEM_USUARIO_HABILITADO        CONSTANT NUMBER := 2127;
  SGU_ITEM_USUARIO_PENDIENTE         CONSTANT NUMBER := 2130;
  SGU_ITEM_USUARIO_SUSPENDIDO        CONSTANT NUMBER := 2128;
  SGU_ITEM_USUARIO_BLOQUEADO         CONSTANT NUMBER := 2129;
  SGU_ITEM_USUARIO_ELIMINADO         CONSTANT NUMBER := 2131;
  REF_ALIAS_BLACKLIST                CONSTANT NUMBER := 1432;

  ------------------------------------------------------------------------------
  -- ESTADOS DE GRUPO
  -- Referencia y estados del ciclo de vida de un grupo.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_GRUPO            CONSTANT NUMBER := 2132;
  SGU_ITEM_GRUPO_ACTIVO              CONSTANT NUMBER := 2133;
  SGU_ITEM_GRUPO_INACTIVO            CONSTANT NUMBER := 2134;
  SGU_ITEM_GRUPO_ELIMINADO           CONSTANT NUMBER := 2141;
  SGU_ITEM_GRUPO_PREPARACION         CONSTANT NUMBER := 2135;

  ------------------------------------------------------------------------------
  --  GRUPOS BASE
  -- Id de los grupos
  ------------------------------------------------------------------------------
  SGU_GRUPO_ALUMNOS                   CONSTANT NUMBER := 359;
  SGU_GRUPO_FUNCIONARIO               CONSTANT NUMBER := 358;
  SGU_GRUPO_EXTERNOS                  CONSTANT NUMBER := 360;
  SGU_GRUPO_SUSPENDIDOS               CONSTANT NUMBER := 361;
  ------------------------------------------------------------------------------
  -- ESTADOS DE ROL
  -- Referencia y estados del ciclo de vida de un rol.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_ROL              CONSTANT NUMBER := 2156;
  SGU_ITEM_ROL_ACTIVO                CONSTANT NUMBER := 2157;
  SGU_ITEM_ROL_INACTIVO              CONSTANT NUMBER := 2158;
  SGU_ITEM_ROL_ELIMINADO             CONSTANT NUMBER := 2160;
  SGU_ITEM_ROL_PENDIENTE             CONSTANT NUMBER := 2159;
  ------------------------------------------------------------------------------
  -- ESTADOS DE FUNCIONALIDAD
  -- Referencia y estados del ciclo de vida de una funcionalidad.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_FUNCIONALIDAD    CONSTANT NUMBER := 2142;
  SGU_ITEM_FUNCIONALIDAD_ACTIVO      CONSTANT NUMBER := 2143;
  SGU_ITEM_FUNCIONALIDAD_INACTIVO    CONSTANT NUMBER := 2144;
  SGU_ITEM_FUNCIONALIDAD_ELIMINADO   CONSTANT NUMBER := 2145;


 SGU_PADRE_CLASIFICACION_PERMISOS CONSTANT NUMBER := 2531;

SGU_ITEM_PERMISO_READ CONSTANT NUMBER := 2533;

  SGU_BIT_PERMISO_READ  CONSTANT NUMBER := 2;
  ------------------------------------------------------------------------------
  -- TIPO DE FUNCIONALIDAD
  -- Referencia padre de los posibles tipos de funcionalidad.
  ------------------------------------------------------------------------------
  SGU_PADRE_TIPO_FUNCIONALIDAD       CONSTANT NUMBER := 2260;
  SGU_TIPO_LISTADO                   CONSTANT NUMBER := 2261;
  SGU_TIPO_FORMULARIO                 CONSTANT NUMBER := 2262;
  ------------------------------------------------------------------------------
  -- ESTADOS DE APLICACI�N
  -- Referencia y estados del ciclo de vida de una aplicaci�n.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_APLICACION       CONSTANT NUMBER := 2151;
  SGU_ITEM_APLICACION_ACTIVO         CONSTANT NUMBER := 2152;
  SGU_ITEM_APLICACION_INACTIVO       CONSTANT NUMBER := 2153;
  SGU_ITEM_APLICACION_ELIMINADO      CONSTANT NUMBER := 2155;
  SGU_ITEM_APLICACION_MANTENCION     CONSTANT NUMBER := 2154;
  ------------------------------------------------------------------------------
  -- ESTADOS DE SISTEMA
  -- Referencia y estados del ciclo de vida de un sistema.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_SISTEMA          CONSTANT NUMBER := 2146;
  SGU_ITEM_SISTEMA_ACTIVO            CONSTANT NUMBER := 2147;
  SGU_ITEM_SISTEMA_INACTIVO          CONSTANT NUMBER := 2148;
  SGU_ITEM_SISTEMA_ELIMINADO         CONSTANT NUMBER := 2149;
  SGU_ITEM_SISTEMA_MANTENCION        CONSTANT NUMBER := 2150;
    ------------------------------------------------------------------------------
  -- ESTADOS DE POLITICAS DE PASSWORD
  -- Referencia y estados de las politicas.
  ------------------------------------------------------------------------------
  SGU_PADRE_ESTADOS_POLITICA         CONSTANT NUMBER := 2263;
  SGU_ITEM_POLITICA_ACTIVO           CONSTANT NUMBER := 2264;
  SGU_ITEM_POLITICA_INACTIVO         CONSTANT NUMBER := 2265;
  SGU_ITEM_POLITICA_ELIMINADO        CONSTANT NUMBER := 2266;
  ------------------------------------------------------------------------------
  -- ESTADOS DE GEDO
  ------------------------------------------------------------------------------
  GDO_ITEM_ETAPA_ELIMINADO          CONSTANT NUMBER := 1;
  ------------------------------------------------------------------------------
  -- VIGENCIA POR RANGO DE FECHAS
  -- Indica si un registro se encuentra dentro o fuera del
  -- rango fecha inicio/fin.
  ------------------------------------------------------------------------------
  SGU_VIGENTE                  		 CONSTANT VARCHAR2(20) := 'Vigente';
  SGU_NO_VIGENTE               		 CONSTANT VARCHAR2(20) := 'No Vigente';
  ------------------------------------------------------------------------------
  -- FLAGS INCLUIR ELIMINADOS
  -- Indica si se deben incluir registros con estado eliminado en los listados.
  ------------------------------------------------------------------------------
  SGU_INCLUDE_DELETED                CONSTANT NUMBER := 1;
  SGU_NOT_INCLUDE_DELETED            CONSTANT NUMBER := 0;

  -- TIPOS DE LOGS
  -- Indica el tipo de log que estas informando.
  ------------------------------------------------------------------------------
  LOG_DEBUG                          CONSTANT NUMBER := 1681;
  LOG_INFO                           CONSTANT NUMBER := 1682;
  LOG_WARNING                        CONSTANT NUMBER := 1684;
  LOG_ERROR                          CONSTANT NUMBER := 1683;
  ------------------------------------------------------------------------------
  -- C�DIGOS DE EXCEPCIONES 
  -- Indica el tipo de error ejecutado.
  ------------------------------------------------------------------------------
  ERROR_NULO       					CONSTANT NUMBER := -20001;  -- Campo nulo o vac�o
  ERROR_FORMATO   					CONSTANT NUMBER := -20002;  -- Formato de campo err�neo
  ERROR_COMPARA   					CONSTANT NUMBER := -20003;  -- Comparaci�n de campos err�nea
  ERROR_LARGO      					CONSTANT NUMBER := -20004;  -- Tama�o texto sobrepasa el l�mite
  ERROR_INSERT     					CONSTANT NUMBER := -20005;  -- Error en la inserci�n
  ERROR_UPDATE     					CONSTANT NUMBER := -20006;  -- Error en la actualizaci�n
  ERROR_DELETE     					CONSTANT NUMBER := -20007;  -- Error en la eliminaci�n
  ERROR_DUPLIC     					CONSTANT NUMBER := -20008;  -- Dato duplicado
  ERROR_PERMISO    					CONSTANT NUMBER := -20009;  -- Sin permiso
  ERROR_NEGOCIO    					CONSTANT NUMBER := -20010;  -- Error en validaci�n de negocio
  ERROR_ACTUALIZAR_ESTADO           CONSTANT NUMBER := -20011;  -- Error al intentar actualizar un registro en estado eliminado
  PROCEDURE_INVALIDO                CONSTANT NUMBER := -20012;  -- Intenta de usar un procedure que otro ya hace su funcion.
  ERROR_ELIMINAR_ESTADO             CONSTANT NUMBER := -20013;  -- Error en la eliminaci�n por no cummplir con el estado eliminado.
  ERROR_DEPENDENCIA                 CONSTANT NUMBER := -20014;  -- No se puede eliminar por registros relacionados.
  ERROR_DEPENDENCIA_PADRE           CONSTANT NUMBER := -20015;  -- No se puede proceder ya que el padre esta en otro estado.
  ERROR_RANGO_FIN  					CONSTANT NUMBER := -20000;  -- �ltimo c�digo de error de aplicaci�n
  ERROR_RANGO_INI  					CONSTANT NUMBER := -20199;  -- Primer c�digo de error de aplicaci�n
  ERROR_GENERAL  					CONSTANT NUMBER := -20200;  -- codigo de error general para caulquier error que quierea ver el DEV y no el USER
  ERROR_VALIDATOR  					CONSTANT NUMBER := -20999;  -- Error en validaci�n del validator, se deja fuera del rango

  ------------------------------------------------------------------------------
  -- MENSAJES DE RESPUESTA
  -- Mesajes genericos y estandar para las respuesta de package.
  ------------------------------------------------------------------------------
  MSG_INSERT_OK                     CONSTANT VARCHAR2(100) := 'Creado exitosamente.';
  MSG_UPDATE_OK                     CONSTANT VARCHAR2(100) := 'Actualizado exitosamente.';
  MSG_DELETE_OK                     CONSTANT VARCHAR2(100) := 'Eliminado exitosamente.';
  -- GEN�RICOS 
  MSG_OK                            CONSTANT VARCHAR2(100) := 'Operaci�n realizada exitosamente.';
  MSG_ERROR_INESPERADO              CONSTANT VARCHAR2(100) := 'Ocurri� un error inesperado. Contacte al administrador.';
  MSG_ERROR_USUARIO                 CONSTANT VARCHAR2(100) := 'Ocurri� un error inesperado(Usuario). Contacte al administrador.';

  MSG_INSERT_ERROR                  CONSTANT VARCHAR2(100) := 'Error al crear.';
  MSG_UPDATE_ERROR                  CONSTANT VARCHAR2(100) := 'Error al actualizar.';
  MSG_DELETE_ERROR                  CONSTANT VARCHAR2(100) := 'Error al eliminar.';
  MSG_NO_ROWS_AFFECTED              CONSTANT VARCHAR2(100) := 'No se afecto ning�n registro.';
  MSG_DELETE_DEPENDENCIA            CONSTANT VARCHAR2(150) := 'No se puede eliminar el registro porque existen registros relacionados.';
  MSG_UPDATE_DEPENDENCIA            CONSTANT VARCHAR2(150) := 'No se puede actualizar el registro por el estado de su padre.';
  MSG_NO_EXIST                      CONSTANT VARCHAR2(150) := 'La entidad no existe.';
  MSG_NO_PARENT                     CONSTANT VARCHAR2(150) := 'No se puede asignar como su propio padre.';
  ------------------------------------------------------------------------------
  -- FORMATOS DE NOMBRES
  -- Indica todos los formatos  de nombre disopnibles a obtener
  ------------------------------------------------------------------------------
  NOMBRE_DEFAULT                    CONSTANT NUMBER := NULL; -- segundo_apellido + primer_apellido + nombres
  NOMBRE_APELLIDO     			    CONSTANT NUMBER :=1;  -- primer nombre� + primer_apellido
  NOMBRES     					    CONSTANT NUMBER :=2;  -- nombres
  SEGUNDO_APELLIDO    				CONSTANT NUMBER :=3;  -- segundo_apellido
  PRIMER_APELLIDO    				CONSTANT NUMBER :=4;  -- primer_apellido
  NOMBRE_COMPLETO                   CONSTANT NUMBER :=5;  -- nombres + primer_apellido + segundo_apellido

  ------------------------------------------------------------------------------
  -- DOMINIOS PARA USUARIOS
  ------------------------------------------------------------------------------
  DOMAIN_FUNCIONARIOS               CONSTANT VARCHAR2(150) := '@unap.cl';
  DOMAIN_ALUMNOS                    CONSTANT VARCHAR2(150) := '@estudiantesunap.cl';
  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA GRL_REFERENCIA
  -- Indica todas las constantes de las referencias padre.
  ------------------------------------------------------------------------------
  REF_ID_APP                        CONSTANT NUMBER := 7;
  REF_ESTADO_INACTIVO               CONSTANT NUMBER := 122;
  REF_ESTADO_ACTIVO                 CONSTANT NUMBER := 123;
  REF_ESTADO_ELIMINADO              CONSTANT NUMBER := 124;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA GRL_REFERENCIA_ITEM
  -- Indica todas las constantes de las referencias item (hijos).
  ------------------------------------------------------------------------------
  REF_ITEM_ID_APP                   CONSTANT NUMBER := 8;
  REF_ITEM_ESTADO_LINEAL            CONSTANT NUMBER := 120;
  REF_ITEM_ESTADO_JERARQUICA        CONSTANT NUMBER := 121;
  REF_ITEM_ESTADO_ACTIVO            CONSTANT NUMBER := 125;
  REF_ITEM_ESTADO_INACTIVO          CONSTANT NUMBER := 126;
  REF_ITEM_ESTADO_ELIMINADO         CONSTANT NUMBER := 127;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA GRL_PARAMETRO
  -- Indica todas las constantes de los parametros.
  ------------------------------------------------------------------------------
  PARAM_ID_APP                      CONSTANT NUMBER := 5;
  PARAM_ESTADO_ACTIVO               CONSTANT NUMBER := 138;
  PARAM_ESTADO_INACTIVO             CONSTANT NUMBER := 139;
  PARAM_ESTADO_ELIMINADO            CONSTANT NUMBER := 2256;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA GRL_PARAMETROROL
  -- Indica todas las constantes de los parametros.
  ------------------------------------------------------------------------------
  PARAMROL_ID_APP                   CONSTANT NUMBER := 6;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA ALR_PLANTILLA
  -- Indica todas las constantes de las plantillas.
  ------------------------------------------------------------------------------
  PLANT_ID_APP                      CONSTANT NUMBER := 10;  
  PLANT_ESTADO_ACTIVO               CONSTANT NUMBER := 153;
  PLANT_ESTADO_INACTIVO             CONSTANT NUMBER := 154;
  PLANT_ESTADO_DESCONTINUADO        CONSTANT NUMBER := 186;
  PLANT_TIPO_PERSONALIZADA          CONSTANT NUMBER := 181;
  PLANT_TIPO_GENERICA               CONSTANT NUMBER := 182;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE SIGAC Y SACPF
  ------------------------------------------------------------------------------   
  SACPF_ROL_ACTIVO   CONSTANT NUMBER := 1;           
  SACPF_ROL_INACTIVO CONSTANT NUMBER := 0;
  SIGAC_ROL_ACTIVO   CONSTANT NUMBER := 1;
  SIGAC_ROL_INACTIVO CONSTANT NUMBER := 0;
  DOCUMENTO_CATEGORIA_DEFAULT CONSTANT NUMBER := 0;    

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA ALR_CAMPO_MENSAJE
  -- Indica todas las constantes de los campos mensajes.
  ------------------------------------------------------------------------------
  CAMPO_MENSAJE_ESTADO_ACTIVO       CONSTANT NUMBER := 175;
  CAMPO_MENSAJE_ESTADO_INACTIVO     CONSTANT NUMBER := 176;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA ALR_CANAL
  -- Indica todas las constantes de los canales.
  ------------------------------------------------------------------------------
  CANAL_ESTADO_ACTIVO CONSTANT NUMBER := 183;
  CANAL_ESTADO_INACTIVO CONSTANT NUMBER := 184;
  CANAL_ESTADO_SUSPENDIDO CONSTANT NUMBER := 185;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE SGR ROL_ACTOS
  ------------------------------------------------------------------------------   
  SRG_ROL_PADRE         CONSTANT NUMBER := 821;
  SRG_ROL_VIGENTE       CONSTANT NUMBER := 2440;  
  SRG_ROL_NO_VIGENTE    CONSTANT NUMBER := 2441;
  SRG_ROL_ELIMINADA     CONSTANT NUMBER := 2442;

  RESTRINGIDO_TRUE      CONSTANT VARCHAR2(150) := 'S';
  RESTRINGIDO_FALSE     CONSTANT VARCHAR2(150) := 'N';
   ------------------------------------------------------------------------------
  -- CONSTANTES DE SGR SOLICITUDES
  ------------------------------------------------------------------------------
  SGR_SOL_RECEPCIONADA       CONSTANT NUMBER := 2451;
  SGR_SOL_ENVIADA            CONSTANT NUMBER := 2450;
  SGR_SOL_BORRADOR           CONSTANT NUMBER := 2449;
  SGR_SOL_ACEPTADA           CONSTANT NUMBER := 2452;
  SGR_SOL_RECHAZADA          CONSTANT NUMBER := 2453;
  SGR_SOL_CANCELADA          CONSTANT NUMBER := 2454;
  SGR_SOL_ASIGNADA           CONSTANT NUMBER := 2464;
  SGR_ROL_ENVIAR_MEMO        CONSTANT NUMBER := 71;
  SGR_ROL_RECIBIR_MEMO       CONSTANT NUMBER := 72;
  SGR_ESTADO_ACCION_LEIDA    CONSTANT NUMBER := 2456;
  SGR_ROL_PERMITIDO          CONSTANT NUMBER := 609;
    ------------------------------------------------------------------------------
  -- CONSTANTES DE SGR ACTOS_ADMINISTRATIVOS
  ------------------------------------------------------------------------------ 
  -- Los SGR_ACTO_TIPO_* son ID_ACTO_ADMINISTRATIVO de SGR_ACTOS_ADMINISTRATIVOS.
  -- OJO: la columna SIGUIENTE_ACTO de esa tabla es un flag (0/1/null) que indica
  -- si el acto encadena otro, NO el id del acto siguiente. El encadenamiento
  -- concreto (INV. SUMARIA -> FISCALIA) vive en PKG_NEG_SGR_BANDEJA.
  SGR_ACTO_ADMINISTRATIVOS_ELIMINADO CONSTANT NUMBER := 2539;
  SGR_ACTO_TIPO_INV_SUMARIA          CONSTANT NUMBER := 80;  -- INV. SUMARIA
  SGR_ACTO_TIPO_FISCALIA             CONSTANT NUMBER := 85;  -- FISCALIA

  ------------------------------------------------------------------------------
  -- CONSTANTES DE GDO
  ------------------------------------------------------------------------------
  GDO_ETAPA_ELIMINADO     CONSTANT NUMBER := 679;
  GDO_PROCESO_ELIMINADO   CONSTANT NUMBER := 680;
  GDO_TRANSICION_ELIMINADO CONSTANT NUMBER := 681;
  GDO_ITEM_ACCION_ELIMINADO CONSTANT NUMBER := 682;
   ------------------------------------------------------------------------------
  -- CONSTANTES DE GDO ETAPA TIPO
  ------------------------------------------------------------------------------
  GDO_PADRE_TIPO_ETAPA CONSTANT NUMBER := 1394;
  GDO_TIPO_INICIO_ETAPA CONSTANT NUMBER := 2548;
  GDO_TIPO_INTERMEDIA_ETAPA CONSTANT NUMBER := 2549;
  GDO_TIPO_FINAL_ETAPA CONSTANT NUMBER := 2550;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE GDO ETAPA ESTADO
  ------------------------------------------------------------------------------
  GDO_PADRE_ESTADO_ETAPA CONSTANT NUMBER := 1395;
  GDO_TIPO_ESTADO_VIGENTE CONSTANT NUMBER := 2551;
  GDO_TIPO_ESTADO_NO_VIGENTE CONSTANT NUMBER := 2552;

------------------------------------------------------------------------------
  -- CONSTANTES DE GDO PROCESO ESTADO
  ------------------------------------------------------------------------------
  GDO_PADRE_ESTADO_PROCESO CONSTANT NUMBER := 1393;
  GDO_PROCESO_ESTADO_VIGENTE CONSTANT NUMBER := 2546;
  GDO_PROCESO_ESTADO_NO_VIGENTE CONSTANT NUMBER := 2547;
   GDO_PROCESO_ESTADO_EN_DISENO CONSTANT NUMBER := 2657;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE GDO ETAPA TIPO ASIGNACION
  ------------------------------------------------------------------------------
  GDO_PADRE_ASIGNACION_ETAPA CONSTANT NUMBER := 1396;
  GDO_ASIGNACION_LISTA CONSTANT NUMBER := 2553;
  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA ALR_GRUPO
  -- Indica todas las constantes de los grupos.
  ------------------------------------------------------------------------------
  GRUPO_ESTADO_ACTIVO       CONSTANT NUMBER := 169;
  GRUPO_ESTADO_INACTIVO     CONSTANT NUMBER := 170;
  GRUPO_ESTADO_ELIMINADO    CONSTANT NUMBER := 187;

  ------------------------------------------------------------------------------
  -- CONSTANTES DE LA TABLA ALR_NOTIFICACION
  -- Indica todas las constantes de las notificaciones.
  ------------------------------------------------------------------------------
  NOTIFICACION_ESTADO_ACTIVA    CONSTANT NUMBER := 163;
  NOTIFICACION_ESTADO_INACTIVA  CONSTANT NUMBER := 164;

  ------------------------------------------------------------------------------
  -- CONSTANTES RELACIONADAS CON EL ESQUEMA SECRETARIAGRALDTIC
  -- Para los ESTADOS de solicitud usar las SGR_SOL_* del bloque
  -- "CONSTANTES DE SGR SOLICITUDES". Aqui solo viven las ACCIONES de la
  -- bitacora (SGR_ESTADO_ACCION), que son un dominio distinto del estado.
  ------------------------------------------------------------------------------
  ACCION_ESTADO_ENTREGADA       CONSTANT NUMBER := 2455;
  ACCION_ESTADO_DERIVADA        CONSTANT NUMBER := 2641;
  ACCION_ESTADO_ACEPTADA        CONSTANT NUMBER := 2642;
  
    
END PKG_GRL_CONFIG;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_GRL_CONFIG" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_GRL_CONFIG" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_GRL_CONFIG" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_GRL_CONFIG" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_GRL_CONFIG" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package PKG_GRL_DATO_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_DATO_ELEMENTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_dato_elemento
-- PURPOSE:    Package para las funciones CRUD de los datos de los atributos de un elementos.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_dato_elemento
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Datos (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Dato (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR 
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

PROCEDURE GetById_Dato (
        p_id_item       IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo   IN grl_dato_elemento.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

PROCEDURE GetAll_Dato (
        p_id_item          IN grl_dato_elemento.id_item%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    );

END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ELEMENTO" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento
-- PURPOSE:    Package para las funciones CRUD de elementos que conforman una estruturas, es decir, la data.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_elemento
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Elemento (
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Elemento (
        p_id_item       IN grl_elemento.id_item%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_ELEMENTO_PADRE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ELEMENTO_PADRE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento_padre
-- PURPOSE:    Package para las funciones CRUD de las relaciones de un elemento con uno o m�s padres
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        4/07/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_elemento_padre
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Get_padres (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_cursor             OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Get_hijos (
        p_id_padre      IN grl_elemento_padre.id_padre%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) ;

END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_ESTRUCTURA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_ESTRUCTURA" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_estructura
-- PURPOSE:    Package para las funciones CRUD de las estruturas definidas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_estructura
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_Estructura (
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Update_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetAll_Estructuras (
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
--------------------------------------------------------
--  DDL for Package PKG_GRL_SUBCOMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_SUBCOMPONENTE" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_subcomponente
-- PURPOSE:    Package para las funciones CRUD de las relaciones entre componentes de una estructuras
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_subcomponente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE Insert_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE Delete_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    );
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE GetById_subcomponente (
        p_id_componente      IN grl_subcomponente.id_componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    );

END;

/
--------------------------------------------------------
--  DDL for Package PKG_LOG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_LOG" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_log 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        02/10/2025   jmaizares         1. Package para la manipulacion de los registros de la tabla log_system 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE REGISTRA_LOG(          
                        p_app_id   in auditor.log_system.app_id%type default null, 
                        p_tipo     in auditor.log_system.tipo%type default null, 
                        p_log_json in auditor.log_system.log_json%type,
                        p_titulo   in auditor.log_system.titulo%type default null, 
                        p_origen   in auditor.log_system.origen%type default null
                      );                      
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE REGISTRA_LOG(          
                        p_app_id   in  auditor.log_system.app_id%type default null, 
                        p_tipo     in  auditor.log_system.tipo%type default null, 
                        p_log_json in  auditor.log_system.log_json%type,
                        p_log_id   out number                        
                      );

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE INSERT_REGISTRO(p_log_id   in auditor.log_system.log_id%type,
                          p_app_id   in auditor.log_system.app_id%type,                            
                          p_log_json in auditor.log_system.log_json%type,
                          p_tipo     in auditor.log_system.tipo%type default null,
                          p_titulo   in auditor.log_system.titulo%type default null,
                          p_origen   in auditor.log_system.origen%type default null                          
                         );
                         
FUNCTION GENERA_LOG_ID RETURN NUMBER;
END;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package PKG_PARAMETRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_PARAMETRO" IS
---
--- Descripci�n: Funciones principales para el CRUD de la tabal "grl_parametro".
--- Autor: Juan Carlos Herqui�igo B.
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
    -- Actualiza los datos de un par�metro.
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
    -- Cambia el estado de un par�metro de la tabla GRL_PARAMETRO
    --------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    --------------------------------------------------
    -- Elimina un par�metro de la tabla GRL_PARAMETRO
    --------------------------------------------------
    PROCEDURE DELETE_FISICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ----------------------------------------------------
    -- Entrega todos los datos del par�metro dado su ID
    ----------------------------------------------------
    PROCEDURE GETBYID_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

    ---------------------------------------------------------------------------------------
    -- Entrega todos los datos de todos los par�metro registrados independiente del estado.
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALL_PARAMETRO (
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    );

END PKG_PARAMETRO;

/
--------------------------------------------------------
--  DDL for Package PKG_PERSONA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_PERSONA" AS   
    
    PROCEDURE GET_ALL (
        p_id IN NUMBER DEFAULT NULL,
        p_rut IN VARCHAR2 DEFAULT NULL,
        p_cursor OUT CLOB
    );

    PROCEDURE INSERT_GRL_PERSONA (
        P_IDENTIFICADOR     IN VARCHAR2,
        P_ID_TIPO_ID        IN NUMBER,    
        P_NOMBRES           IN VARCHAR2,
        P_PRIMER_APELLIDO   IN VARCHAR2,
        P_SEGUNDO_APELLIDO  IN VARCHAR2 DEFAULT NULL,
        P_FECHA_NAC         IN DATE DEFAULT NULL,
        P_NOMBRE_SOCIAL     IN VARCHAR2 DEFAULT NULL,
        P_ID_SEXO           IN NUMBER,
        P_ID_GENERO         IN NUMBER,
        P_OTRO_GENERO       IN VARCHAR2 DEFAULT NULL,
        P_CON_DISCAPACIDAD  IN VARCHAR2 DEFAULT 'N',
        P_DISCAPACIDAD      IN VARCHAR2 DEFAULT NULL,
        P_ID_NACIONALIDAD   IN NUMBER,
        P_FALLECIDO         IN VARCHAR2 DEFAULT 'N',
        P_ID_USUARIO_MOD    IN NUMBER DEFAULT NULL,
        P_FEC_ULT_MOD       IN DATE DEFAULT SYSDATE,
        O_ID_PERSONA        OUT NUMBER
    );

    PROCEDURE INSERT_GRL_PERSONA_DATO_PERSONAL (
        P_ID_PERSONA          IN NUMBER,
        P_CELULAR             IN VARCHAR2 DEFAULT NULL,
        P_FONO                IN VARCHAR2 DEFAULT NULL,
        P_EMAIL               IN VARCHAR2 DEFAULT NULL,
        P_FEC_ULT_ACT         IN DATE DEFAULT SYSDATE,
        P_ID_ESTADO_CIVIL     IN NUMBER DEFAULT NULL,
        P_ID_SITUAC_MILITAR   IN NUMBER DEFAULT NULL,
        P_ID_USUARIO_MOD      IN NUMBER DEFAULT NULL,
        P_FEC_ULT_MOD         IN DATE DEFAULT SYSDATE
    );

    PROCEDURE INSERT_GRL_DIRECCION (        
        P_CALLE                   IN VARCHAR2,
        P_NUMERO                  IN VARCHAR2,
        P_DEPTO                   IN VARCHAR2 DEFAULT NULL,
        P_ID_COMUNA               IN NUMBER DEFAULT NULL,
        P_ID_REGION               IN NUMBER DEFAULT NULL,
        P_ID_CLASE_DIRECCION      IN NUMBER DEFAULT NULL,
        P_LATITUD                 IN NUMBER DEFAULT NULL,
        P_LONGITUD                IN NUMBER DEFAULT NULL,
        P_COD_POSTAL              IN VARCHAR2 DEFAULT NULL,
        P_CIUDAD                  IN VARCHAR2 DEFAULT NULL,
        P_ID_PAIS                 IN NUMBER DEFAULT NULL,
        P_FEC_ULT_ACT             IN DATE DEFAULT NULL,
        P_ID_USUARIO_MOD          IN NUMBER DEFAULT NULL,
        O_ID_DIRECCION            OUT NUMBER,
        O_RESPUESTA               OUT VARCHAR2
    );

    PROCEDURE INSERT_GRL_PERSONA_DIRECCION (
        ID_PERSONA      IN NUMBER,    
        ID_DIRECCION    IN NUMBER,
        ID_TIPO         IN NUMBER,
        O_RESPUESTA     OUT VARCHAR2
    );   

    PROCEDURE GUARDAR_PERSONA (
        P_JSON IN CLOB,
        P_CURSOR        OUT SYS_REFCURSOR
    );

    FUNCTION MENSAJE_RETORNO (
        P_TIPO IN VARCHAR2,
        P_MENSAJE IN VARCHAR2
    ) RETURN SYS_REFCURSOR;

    FUNCTION SQLERRM_SIN_CODIGO (
        P_SQLERRM IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION GETNOMBRE_PERSONA (
        p_id IN      grl_persona.id_persona%type, 
        p_formato in NUMBER DEFAULT NULL        
    ) RETURN varchar2;


END PKG_PERSONA;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_PERSONA" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_PERSONA" TO "SIGESUSTIC";
--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA" IS    
---
--- Descripci�n: Funciones principales para el CRUD de la tabla "grl_referencia".
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
    -- Entrega todos los datos del par�metro dado su ID
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
--------------------------------------------------------
--  DDL for Package PKG_REFERENCIA_SISTEMA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_REFERENCIA_SISTEMA" IS
---
--- Descripci�n: Funciones principales para el CRUD de la tabla "grl_referencia_sistema".
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
    -- Elimina la relaci�n REFERENCIA-SISTEMA.
    ----------------------------------------------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    );

    ----------------------------------------------------------------------------
    -- Elimina la relaci�n REFERENCIA-SISTEMA.
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
--------------------------------------------------------
--  DDL for Package PKG_VALIDACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_VALIDACIONES" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_validaciones 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        15/10/2025   @author         1. Package generico con diferentes procedimientos de validaciones
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

                      
FUNCTION tamanio_campo( 
                        p_texto     in varchar2 ,         
                        p_tamanio   in number
                       ) return boolean;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

FUNCTION es_numero( 
                    p_var     in varchar2                  
                  ) return boolean;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

FUNCTION es_fecha( 
                  p_fecha     in varchar2
                 ) return boolean;






END;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SIGESUSTIC";
--------------------------------------------------------
--  DDL for Package PKG_VALIDATOR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_VALIDATOR" AS

    FUNCTION RULE(
        p_name  IN VARCHAR2,
        p_value IN VARCHAR2,
        p_rules IN VARCHAR2
    ) RETURN T_RULE;

    FUNCTION RULE(
        p_name  IN VARCHAR2,
        p_value IN NUMBER,
        p_rules IN VARCHAR2
    ) RETURN T_RULE;

    FUNCTION RULE(
        p_name     IN VARCHAR2,
        p_value    IN DATE,
        p_rules    IN VARCHAR2,
        p_min_date IN DATE DEFAULT NULL,
        p_max_date IN DATE DEFAULT NULL
    ) RETURN T_RULE;

    FUNCTION RULE(
        p_name  IN VARCHAR2,
        p_value IN CLOB,
        p_rules IN VARCHAR2
    ) RETURN T_RULE;

    PROCEDURE VALIDATE(p_list IN T_RULES);
    PROCEDURE VALIDATE_ALL(p_list IN T_RULES);
    FUNCTION GET_ERRORS(p_list IN T_RULES) RETURN T_ERRORS;

END PKG_VALIDATOR;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package PKG_VISORES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_VISORES" AS 

    PROCEDURE GETALL_LOG_SYSTEM (
        p_param                 number,
        p_cursor                OUT SYS_REFCURSOR
    );
    
    PROCEDURE GETALL_AUDITOR (
        p_table                 VARCHAR2,
        p_fetch                 VARCHAR2,
        p_limit                 NUMBER DEFAULT 0,
        p_date                  TIMESTAMP DEFAULT NULL,
        p_cursor                OUT SYS_REFCURSOR
    );
    
    PROCEDURE GETSTATS_LOG_SYSTEM(
        p_cursor                OUT SYS_REFCURSOR
    ) ;

END PKG_VISORES;

/
