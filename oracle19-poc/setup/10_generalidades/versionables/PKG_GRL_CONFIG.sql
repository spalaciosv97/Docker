--------------------------------------------------------
--  DDL for Package PKG_GRL_CONFIG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENERALIDADES"."PKG_GRL_CONFIG" AS

  /*
   * PKG_GRL_CONFIG — Paquete de configuración global del sistema SGU
   * ---------------------------------------------------------------
   * Centraliza las constantes de referencia e ítems del sistema con
   * el objetivo de evitar consultas innecesarias a la base de datos
   * y garantizar consistencia en los procedimientos almacenados (PL).
   *
   * Autor  : Brahyant Millán
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
  -- ESTADOS DE APLICACIÓN
  -- Referencia y estados del ciclo de vida de una aplicación.
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
  -- CÓDIGOS DE EXCEPCIONES 
  -- Indica el tipo de error ejecutado.
  ------------------------------------------------------------------------------
  ERROR_NULO       					CONSTANT NUMBER := -20001;  -- Campo nulo o vacío
  ERROR_FORMATO   					CONSTANT NUMBER := -20002;  -- Formato de campo erróneo
  ERROR_COMPARA   					CONSTANT NUMBER := -20003;  -- Comparación de campos errónea
  ERROR_LARGO      					CONSTANT NUMBER := -20004;  -- Tamaño texto sobrepasa el límite
  ERROR_INSERT     					CONSTANT NUMBER := -20005;  -- Error en la inserción
  ERROR_UPDATE     					CONSTANT NUMBER := -20006;  -- Error en la actualización
  ERROR_DELETE     					CONSTANT NUMBER := -20007;  -- Error en la eliminación
  ERROR_DUPLIC     					CONSTANT NUMBER := -20008;  -- Dato duplicado
  ERROR_PERMISO    					CONSTANT NUMBER := -20009;  -- Sin permiso
  ERROR_NEGOCIO    					CONSTANT NUMBER := -20010;  -- Error en validación de negocio
  ERROR_ACTUALIZAR_ESTADO           CONSTANT NUMBER := -20011;  -- Error al intentar actualizar un registro en estado eliminado
  PROCEDURE_INVALIDO                CONSTANT NUMBER := -20012;  -- Intenta de usar un procedure que otro ya hace su funcion.
  ERROR_ELIMINAR_ESTADO             CONSTANT NUMBER := -20013;  -- Error en la eliminación por no cummplir con el estado eliminado.
  ERROR_DEPENDENCIA                 CONSTANT NUMBER := -20014;  -- No se puede eliminar por registros relacionados.
  ERROR_DEPENDENCIA_PADRE           CONSTANT NUMBER := -20015;  -- No se puede proceder ya que el padre esta en otro estado.
  ERROR_RANGO_FIN  					CONSTANT NUMBER := -20000;  -- Último código de error de aplicación
  ERROR_RANGO_INI  					CONSTANT NUMBER := -20199;  -- Primer código de error de aplicación
  ERROR_GENERAL  					CONSTANT NUMBER := -20200;  -- codigo de error general para caulquier error que quierea ver el DEV y no el USER
  ERROR_VALIDATOR  					CONSTANT NUMBER := -20999;  -- Error en validación del validator, se deja fuera del rango

  ------------------------------------------------------------------------------
  -- MENSAJES DE RESPUESTA
  -- Mesajes genericos y estandar para las respuesta de package.
  ------------------------------------------------------------------------------
  MSG_INSERT_OK                     CONSTANT VARCHAR2(100) := 'Creado exitosamente.';
  MSG_UPDATE_OK                     CONSTANT VARCHAR2(100) := 'Actualizado exitosamente.';
  MSG_DELETE_OK                     CONSTANT VARCHAR2(100) := 'Eliminado exitosamente.';
  -- GENÉRICOS 
  MSG_OK                            CONSTANT VARCHAR2(100) := 'Operación realizada exitosamente.';
  MSG_ERROR_INESPERADO              CONSTANT VARCHAR2(100) := 'Ocurrió un error inesperado. Contacte al administrador.';
  MSG_ERROR_USUARIO                 CONSTANT VARCHAR2(100) := 'Ocurrió un error inesperado(Usuario). Contacte al administrador.';

  MSG_INSERT_ERROR                  CONSTANT VARCHAR2(100) := 'Error al crear.';
  MSG_UPDATE_ERROR                  CONSTANT VARCHAR2(100) := 'Error al actualizar.';
  MSG_DELETE_ERROR                  CONSTANT VARCHAR2(100) := 'Error al eliminar.';
  MSG_NO_ROWS_AFFECTED              CONSTANT VARCHAR2(100) := 'No se afecto ningún registro.';
  MSG_DELETE_DEPENDENCIA            CONSTANT VARCHAR2(150) := 'No se puede eliminar el registro porque existen registros relacionados.';
  MSG_UPDATE_DEPENDENCIA            CONSTANT VARCHAR2(150) := 'No se puede actualizar el registro por el estado de su padre.';
  MSG_NO_EXIST                      CONSTANT VARCHAR2(150) := 'La entidad no existe.';
  MSG_NO_PARENT                     CONSTANT VARCHAR2(150) := 'No se puede asignar como su propio padre.';
  ------------------------------------------------------------------------------
  -- FORMATOS DE NOMBRES
  -- Indica todos los formatos  de nombre disopnibles a obtener
  ------------------------------------------------------------------------------
  NOMBRE_DEFAULT                    CONSTANT NUMBER := NULL; -- segundo_apellido + primer_apellido + nombres
  NOMBRE_APELLIDO     			    CONSTANT NUMBER :=1;  -- primer nombre  + primer_apellido
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
