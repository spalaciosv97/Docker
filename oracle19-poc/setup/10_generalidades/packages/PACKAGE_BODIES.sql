--------------------------------------------------------
--  AJUSTE LOCAL PoC Docker — CONFIRMAR CON QA
--
--  PKG_REFERENCIA insertaba/leia GRL_REFERENCIA.FECHA_CREACION, pero
--  esa columna NO EXISTE: la tabla tiene FECHA_REG. FECHA_CREACION no
--  aparece en ningun DDL de la entrega, solo en este package body.
--
--  Sin esto, PKG_REFERENCIA queda INVALID con ORA-00904.
--
--  Se reemplazo FECHA_CREACION -> FECHA_REG (4 ocurrencias). NO se
--  toco la clave JSON '\$.fecha_creacion' en minusculas, que es un
--  nombre de campo de salida y no una columna.
--
--  PREGUNTAR A QA: es la tabla la desactualizada o el package?
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body PKG_ESTRUCTURA_NEGOCIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_ESTRUCTURA_NEGOCIO" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_estructura
-- PURPOSE:    Package para las funciones de negocio el manejo de estructuras
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la funciones de negocio de las estructuras
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app        NUMBER := 7;     -- ID del package
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_logId         NUMBER;
    ----------------------------------------
    -- Propaga_atributo asigna el atributo a los elementos ya existente en la extructura que no tienen el atributo asignado.
    ----------------------------------------
    PROCEDURE Propaga_atributo (
        p_id_atributo       IN  grl_atributo.id_atributo%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    ) IS

    v_id_atributo      grl_atributo.id_atributo%TYPE   := p_id_atributo;
    v_id_componente    grl_atributo.id_componente%TYPE;
    v_valor_default    grl_atributo.valor_default%TYPE;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('p_id_atributo', p_id_atributo, 'required|int')
        ));

        --- Se recupera datos del atributo a ser propagado
        SELECT id_componente, valor_default
        INTO   v_id_componente, v_valor_default
        FROM grl_atributo
        WHERE id_atributo = v_id_atributo;

        --- Inserta los atributos vigentes que tenga asociado el nivel donde es insertado el elemento.
        ---
        insert into grl_dato_elemento (id_item, id_atributo, valor, ult_fec_act)
        select id_item, v_id_atributo, v_valor_default, sysdate
        from grl_elemento e
        where not exists (select 'x' from grl_dato_elemento where id_atributo = v_id_atributo and id_item = e.id_item)
        and id_componente = v_id_componente;

        COMMIT;

        OPEN p_cursor FOR
                SELECT v_id_atributo id, CONST.MSG_INSERT_OK AS message FROM dual;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_atributo'    VALUE v_id_atributo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Propaga_atributo;


    ----------------------------------------
    -- Mover_Elemento mueve un elementos y sus hijos a un nuevo item padre.
    ----------------------------------------
    PROCEDURE Mover_Elemento (
        p_id_item           IN  grl_elemento.id_item%TYPE,
        p_id_padre_nuevo    IN  grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    ) IS

    v_id_item               grl_elemento.id_item%TYPE   := p_id_item;
    v_id_nuevo_padre        grl_elemento.id_padre%TYPE  := p_id_padre_nuevo;
    v_id_estructura_item    grl_componente.id_estructura%TYPE;
    v_id_estructura_padre   grl_componente.id_estructura%TYPE;
    v_id_componente_item    grl_elemento.id_componente%TYPE;
    v_id_componente_padre   grl_elemento.id_componente%TYPE;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('id_item', v_id_item, 'required|int'),
                VALIDATOR.RULE('id_padre_nuevo', v_id_nuevo_padre, 'required|int')
        ));

        BEGIN
            --- Se recuperan datos del elemento que ser� movido.
            SELECT c.id_estructura, e.id_componente
            INTO   v_id_estructura_item, v_id_componente_item
            FROM grl_componente c, grl_elemento e
            WHERE c.id_componente = e.id_componente
            AND e.id_item = v_id_item;

            --- Se recuperan datos del padre
            SELECT c.id_estructura, e.id_componente
            INTO   v_id_estructura_padre, v_id_componente_padre
            FROM grl_componente c, grl_elemento e
            WHERE c.id_componente = e.id_componente
            AND e.id_item = v_id_nuevo_padre;

            IF (v_id_estructura_item != v_id_estructura_padre) THEN
                OPEN p_cursor FOR
                    SELECT p_id_item id, 'El padre no corresponde a la misma estructura.' AS message FROM dual;
                return;
            END IF;

            SELECT Count(1) INTO v_rows
            FROM grl_subcomponente
            WHERE id_componente = v_id_componente_item 
            AND id_padre = v_id_componente_padre;

            IF (v_rows <= 0) THEN
                OPEN p_cursor FOR
                    SELECT p_id_item id, 'El movimiento no es v�lido.' AS message FROM dual;
                return;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                OPEN p_cursor FOR
                    SELECT p_id_item id, CONST.ERROR_UPDATE AS message FROM dual;
                return;
        END;

        --- Se hace el movimiento del elemento.
        ---
        update grl_elemento 
        set id_padre = v_id_nuevo_padre
        where id_item = v_id_item;

        OPEN p_cursor FOR
                    SELECT p_id_item id, 'Movimiento realizado con �xito.' AS message FROM dual;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_atributo'    VALUE v_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Mover_Elemento;

    PROCEDURE Get_datos_Elemento (
        p_id_item           IN  grl_elemento.id_item%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    ) IS

    v_id_item               grl_elemento.id_item%TYPE   := p_id_item;
    v_id_componente         grl_componente.id_componente%TYPE;
    v_rows                  NUMBER;
    v_select                VARCHAR2(4000) := 'SELECT ';
    v_coma                  varchar2(5) := ' ';
    CURSOR c_atributos IS
        SELECT a.id_atributo, a.nombre, a.id_tipo_dato, a.largo, a.objeto, a.columna_id, a.columna_data, a.posicion
        FROM grl_atributo a, grl_elemento e
        WHERE a.id_estado = 73
        AND a.id_componente = e.id_componente
        AND e.id_item = v_id_item
        ORDER BY a.posicion;

    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('id_item', v_id_item, 'required|int')
        ));

        --- Se recuperan los atributos asociado al elemento.
        FOR atrib IN c_atributos LOOP
            CASE 
                WHEN atrib.id_tipo_dato = 131 THEN --- Tipo char/varchar2
                    v_select := v_select||v_coma||'(select valor from grl_dato_elemento where id_item = '||to_char(v_id_item)||' and id_atributo = '||to_char(atrib.id_atributo)||') as '||trim(atrib.nombre);
                WHEN atrib.id_tipo_dato = 132 THEN --- Tipo INT (sin decimales)
                    v_select := v_select||v_coma||'(select to_number(valor) from grl_dato_elemento where id_item = '||to_char(v_id_item)||' and id_atributo = '||to_char(atrib.id_atributo)||') as '||trim(atrib.nombre);
                WHEN atrib.id_tipo_dato = 133 THEN --- Tipo number (con decimales)
                    v_select := v_select||v_coma||'(select to_number(valor) from grl_dato_elemento where id_item = '||to_char(v_id_item)||' and id_atributo = '||to_char(atrib.id_atributo)||') as '||trim(atrib.nombre);
                WHEN atrib.id_tipo_dato = 134 THEN --- Tipo date
                    v_select := v_select||v_coma||'(select to_date(valor,''dd-mm-yyyy hh24:mi:ss'') from grl_dato_elemento where id_item = '||to_char(v_id_item)||' and id_atributo = '||to_char(atrib.id_atributo)||') as '||trim(atrib.nombre);
                WHEN atrib.id_tipo_dato = 75  THEN --- Tipo lista
                    v_select := v_select||v_coma||'(select '||atrib.columna_data||' from '||atrib.objeto||' where '||atrib.columna_id||' = (select to_number(valor) from grl_dato_elemento where id_item = '||to_char(v_id_item)||' and id_atributo = '||to_char(atrib.id_atributo)||')) as '||trim(atrib.nombre);
            END CASE;
            v_coma := ', ';
        END LOOP;
        v_select := v_select||' FROM DUAL'; 

        DBMS_OUTPUT.PUT_LINE(v_select);

        OPEN p_cursor FOR
                    v_select;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_atributo'    VALUE v_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Get_datos_Elemento;


    ----------------------------------------
    -- SELECT que retorna la definici�n de la estructura en forma de �rbol.
    ----------------------------------------
    PROCEDURE Get_estructura(
        p_id_estructura      IN  grl_estructura.id_estructura%TYPE,
        p_cursor             OUT SYS_REFCURSOR 
    ) IS

    p_id_componente_raiz       GRL_COMPONENTE.id_componente%TYPE;
    BEGIN
        --- Se recupera el componente raiz de la estructura, si a�n no esta definido da error.
        BEGIN
            SELECT id_componente INTO p_id_componente_raiz
            FROM grl_componente c
            WHERE NOT EXISTS (select 'x' from grl_subcomponente where id_componente = c.id_componente )
            AND id_estructura = p_id_estructura;
        EXCEPTION
            WHEN TOO_MANY_ROWS THEN
                  OPEN p_cursor FOR SELECT 'ERROR' status, p_id_estructura AS "id_estructura", 'Estructura tiene m�s de nodo ra�z.' AS "message" FROM DUAL;
                  RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            WHEN NO_DATA_FOUND THEN
                  OPEN p_cursor FOR SELECT 'ERROR' status, p_id_estructura AS "id_estructura", 'Estructura no tiene un nodo raiz.' AS "message" FROM DUAL;
                  RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            WHEN OTHERS THEN
                  OPEN p_cursor FOR SELECT 'ERROR' status, p_id_estructura AS "id_estructura", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
                  RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END;
        OPEN p_cursor FOR
             SELECT rownum correlativo, est.id_componente, substr('                     ',1,level*2)||est.componente nombre, level nivel
             FROM (
                    select c.id_componente, c.nombre componente, c.descripcion, sc.id_padre, cp.nombre padre
                    from grl_componente c left outer join grl_subcomponente sc ON sc.id_componente = c.id_componente
                      left outer join grl_componente cp ON cp.id_componente = sc.id_padre
                    where c.id_estructura = p_id_estructura) est
            start with id_componente = p_id_componente_raiz connect by prior id_componente = id_padre;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_estructura'  VALUE p_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Get_estructura;


    PROCEDURE Get_componentes_hijos (
        p_id_elemento          IN  grl_elemento.id_item%TYPE,
        p_cursor               OUT SYS_REFCURSOR  
    ) IS

    v_id_elemento           grl_elemento.id_item%TYPE := p_id_elemento;
    v_id_componente         grl_elemento.id_componente%TYPE;
    v_rows                  NUMBER;

    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_elemento', v_id_elemento, 'required|int')
        ));

        -- Se recupera el componente del elemento dado
        SELECT id_componente INTO v_id_componente 
        FROM grl_elemento 
        WHERE id_item = v_id_elemento;

        -- Se recuperan los tipo de componente hijos que puede tener el elemento dado.
        OPEN p_cursor FOR
             SELECT c.id_componente, c.nombre componente
             FROM grl_componente c
            WHERE EXISTS (SELECT 'x' FROM grl_subcomponente WHERE id_componente = c.id_componente and id_padre = v_id_componente);

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_elemento'    VALUE v_id_elemento,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Get_componentes_hijos;

    PROCEDURE Get_arbol_elementos (
        p_id_estructura        IN grl_estructura.id_estructura%TYPE,
        p_cursor               OUT SYS_REFCURSOR  
    ) IS

    v_id_pto_partida        grl_estructura.punto_inicio%TYPE;
    v_rows                  NUMBER;

    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('p_id_estructura', p_id_estructura, 'required|int')
        ));

        -- Se recupera el punto de inicio de la estructura en glr_elemento.
        SELECT punto_inicio INTO v_id_pto_partida 
        FROM grl_estructura 
        WHERE id_estructura = p_id_estructura;

        -- Se recuperan los tipo de componente hijos que puede tener el elemento dado.
        OPEN p_cursor FOR
             SELECT id_item, nombre, id_componente, id_padre
             FROM grl_elemento 
            START WITH id_item = v_id_pto_partida CONNECT BY PRIOR id_item = id_padre;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_estructura'    VALUE p_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Get_arbol_elementos;

    PROCEDURE Get_objeto_lista (
        p_cursor               OUT SYS_REFCURSOR  
    ) IS

    v_rows                  NUMBER;

    BEGIN
        -- Se recuperan los objetos diponibles para las listas.
        OPEN p_cursor FOR
             SELECT id_item, objeto, alias
             FROM GRL_OBJETO_LISTA_VW 
             ORDER BY objeto;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);

    END Get_objeto_lista;


    PROCEDURE Get_objeto_columnas (
        p_objeto               IN  VARCHAR2,
        p_cursor               OUT SYS_REFCURSOR  
    ) IS

    v_rows                  NUMBER;

    BEGIN
        -- Se recuperan los objetos diponibles para las listas.
        OPEN p_cursor FOR
             select column_name columna, data_type tipo, data_length
            from user_tab_columns 
            where table_name = p_objeto
            order by column_id;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_objeto'         VALUE p_objeto,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);

    END Get_objeto_columnas;


    PROCEDURE Get_lista (
        p_id_atributo          IN  NUMBER,
        p_cursor               OUT SYS_REFCURSOR  
    ) IS

    v_rows                  NUMBER;
    v_objeto                grl_atributo.objeto%TYPE;
    v_columna_id            grl_atributo.columna_id%TYPE;
    v_columna_data          grl_atributo.columna_data%TYPE;

    v_sql                   VARCHAR2(500);
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('p_id_atributo', p_id_atributo, 'required|int')
        ));

        --- Se obtiene datos del atributo
        SELECT objeto, columna_id, columna_data INTO v_objeto, v_columna_id, v_columna_data
        FROM grl_atributo
        WHERE id_atributo = p_id_atributo;

        --- Se conforma la query
        v_sql := 'select '||v_columna_id||' id, '||v_columna_data||' valor from '||v_objeto||' order by 2';

        -- Se recuperan los objetos diponibles para las listas.
        OPEN p_cursor FOR v_sql;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_atributo'    VALUE p_id_atributo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data);

    END Get_lista;

END pkg_estructura_negocio;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ARCHIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ARCHIVO" AS

    v_idApp NUMBER := CONST.APP_CGA;
    v_data CLOB;

    PROCEDURE PROC_INSERT_ARCHIVO(
        p_nombre  IN GRL_ARCHIVO.NOMBRE%TYPE,
        p_alias   IN GRL_ARCHIVO.ALIAS%TYPE,
        p_ruta    IN GRL_ARCHIVO.RUTA%TYPE,
        p_estado  IN GRL_ARCHIVO.ESTADO%TYPE,
        p_app     IN GRL_ARCHIVO.APP%TYPE,
        p_usuario IN GRL_ARCHIVO.USUARIO%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_id           GRL_ARCHIVO.ID_ARCHIVO%type;
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
        
    BEGIN
    
     VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('p_nombre',  p_nombre, 'required|string|min=3|max=255'),
            VALIDATOR.RULE('p_alias',   p_alias,  'string|min=10|max=1000'),
            VALIDATOR.RULE('p_ruta',    p_ruta,   'required|string|max=2000'),
            VALIDATOR.RULE('p_estado',  p_estado, 'required|string|max=20'),
            VALIDATOR.RULE('p_app',     p_app,    'string|max=255'),
            VALIDATOR.RULE('p_usuario', p_usuario,'int')
        ));
        
        INSERT INTO GRL_ARCHIVO(
            NOMBRE, 
            ALIAS, 
            RUTA, 
            ESTADO, 
            APP, 
            Usuario)
        VALUES (
            p_nombre,
            p_alias, 
            p_ruta,
            p_estado,
            p_app, 
            p_usuario
        )
        RETURNING id_archivo INTO v_id;

        --COMMIT;
        
        OPEN p_cursor FOR SELECT v_id AS "uid", CONST.MSG_INSERT_OK 
        AS "message", 1 "state"  FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            --ROLLBACK;
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_nombre' VALUE p_nombre,
                           'p_alias' VALUE p_alias,
                           'p_ruta' VALUE p_ruta,
                           'p_estado' VALUE p_estado,
                           'p_app' VALUE p_app,
                           'p_usuario' VALUE p_usuario,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
            
    END PROC_INSERT_ARCHIVO;

    PROCEDURE PROC_UPDATE_ARCHIVO(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_nombre IN GRL_ARCHIVO.NOMBRE%TYPE,
        p_alias IN GRL_ARCHIVO.ALIAS%TYPE,
        p_estado IN GRL_ARCHIVO.ESTADO%TYPE,
        p_app IN GRL_ARCHIVO.APP%TYPE,
        p_usuario IN GRL_ARCHIVO.USUARIO%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
    
     VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('p_id_archivo',  p_id_archivo, 'required|int'),
            VALIDATOR.RULE('p_nombre',      p_nombre,     'string|min=3|max=255'),
            VALIDATOR.RULE('p_alias',       p_alias,      'string|min=10|max=1000'),
            VALIDATOR.RULE('p_estado',      p_estado,     'string|max=20'),
            VALIDATOR.RULE('p_app',         p_app,        'string|max=255'),
            VALIDATOR.RULE('p_usuario',     p_usuario,    'required|int')
        ));
        
        UPDATE GRL_ARCHIVO
        SET NOMBRE  = NVL(p_nombre,  NOMBRE),
            ALIAS   = NVL(p_alias,   ALIAS),
            ESTADO  = NVL(p_estado,  ESTADO),
            APP     = NVL(p_app,     APP),
            USUARIO = NVL(p_usuario, USUARIO)
        WHERE ID_ARCHIVO = p_id_archivo;

        OPEN p_cursor FOR SELECT p_id_archivo AS "uid", CONST.MSG_UPDATE_OK 
        AS "message", 1 "state"  FROM DUAL;
        
    EXCEPTION
        WHEN OTHERS THEN
            --ROLLBACK;
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_nombre' VALUE p_nombre,
                           'p_alias' VALUE p_alias,
                           'p_estado' VALUE p_estado,
                           'p_app' VALUE p_app,
                           'p_usuario' VALUE p_usuario,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
            
    END PROC_UPDATE_ARCHIVO;
    
    
-- no se esta usando
    PROCEDURE PROC_DELETE_ARCHIVO(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
            v_id           GRL_ARCHIVO.ID_ARCHIVO%type;
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        DELETE FROM GRL_ARCHIVO WHERE id_archivo = p_id_archivo;
        
        OPEN p_cursor FOR SELECT p_id_archivo AS "uid", CONST.MSG_DELETE_OK 
                AS "message", 1 "state"  FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            --ROLLBACK;
            --RAISE_APPLICATION_ERROR(-22003, 'Error en proc_delete_version: ' || SQLERRM);
             v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_archivo' VALUE p_id_archivo,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
            
    END PROC_DELETE_ARCHIVO;

    PROCEDURE PROC_SELECT_ARCHIVO(
        p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_proyecto   IN GRL_ARCHIVO.APP%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR
        SELECT ID_ARCHIVO                                      AS "archivoId",
               NOMBRE                                          AS "nombre",
               ALIAS                                           AS "alias",
               RUTA                                            AS "ruta",
               ESTADO                                          AS "estadoArchivo",
               APP                                             AS "proyecto",
               USUARIO                                         AS "usuario",
               TO_CHAR(FECHA_SUBIDA, 'DD/MM/YYYY HH24:MI:SS')  AS "fechaSubida"
          FROM GRL_ARCHIVO
         WHERE ID_ARCHIVO = p_id_archivo
           AND APP = p_proyecto;
           
    END PROC_SELECT_ARCHIVO;

    PROCEDURE PROC_LIST_ARCHIVOS(
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT ID_ARCHIVO                                      AS "archivoId",
               NOMBRE                                          AS "nombre",
               ALIAS                                           AS "alias",
               RUTA                                            AS "ruta",
               ESTADO                                          AS "estadoArchivo",
               APP                                             AS "proyecto",
               USUARIO                                         AS "usuario",
               TO_CHAR(FECHA_SUBIDA, 'DD/MM/YYYY HH24:MI:SS')  AS "fechaSubida"
          FROM GRL_ARCHIVO;
    END PROC_LIST_ARCHIVOS;

-- no se esta usando
    PROCEDURE proc_delete_archivo_v2(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        UPDATE GRL_ARCHIVO
           SET estado = '0'
         WHERE id_archivo = p_id_archivo
           AND estado = '1';

        --COMMIT;

        OPEN p_cursor FOR
            SELECT *
              FROM GRL_ARCHIVO
             WHERE id_archivo = p_id_archivo;

    EXCEPTION
        WHEN OTHERS THEN
            --ROLLBACK;
            RAISE_APPLICATION_ERROR(-22003, 'Error en proc_delete: ' || SQLERRM);
    END proc_delete_archivo_v2;

    PROCEDURE PROC_DELETE_HIJOS_EXTERNOS(
            p_id_archivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
            p_cursor     OUT SYS_REFCURSOR
        ) AS
            v_sql              VARCHAR2(4000);
            v_errorCode        NUMBER;
            v_errorMessage     VARCHAR2(4000);
            v_idLog            NUMBER;
        
            e_sin_permisos     EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_sin_permisos, -1031);
        BEGIN
            FOR r IN (
                SELECT a.owner AS esquema_hijo, a.table_name AS tabla_hija, b.column_name AS columna_hija
                FROM all_constraints a
                JOIN all_cons_columns b
                     ON a.constraint_name = b.constraint_name AND a.owner = b.owner
                JOIN all_constraints c
                     ON a.r_constraint_name = c.constraint_name AND a.r_owner = c.owner
                WHERE a.constraint_type = 'R'
                  AND c.table_name = 'GRL_ARCHIVO'
                  AND c.owner = 'GENERALIDADES'
                  AND a.table_name != 'GRL_ARCHIVO_VERSION'   -- excluida: se maneja en PROC_DELETE_VERSION
            ) LOOP
                v_sql := 'DELETE FROM ' || r.esquema_hijo || '.' || r.tabla_hija ||
                         ' WHERE ' || r.columna_hija || ' = :1';
        
                BEGIN
                    EXECUTE IMMEDIATE v_sql USING p_id_archivo;
                EXCEPTION
                    WHEN e_sin_permisos THEN
                        SELECT JSON_OBJECT(
                                'p_id_archivo' VALUE p_id_archivo,
                                'esquema_hijo' VALUE r.esquema_hijo,
                                'tabla_hija'   VALUE r.tabla_hija,
                                'ora_code'     VALUE -1031,
                                'ora_msg'      VALUE 'Sin permisos DELETE sobre ' || r.esquema_hijo || '.' || r.tabla_hija
                                RETURNING CLOB)
                        INTO v_data
                        FROM DUAL;
                        PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_idLog);
                        OPEN p_cursor FOR SELECT v_idLog AS "uid",
                            'Sin permisos para eliminar en ' || r.esquema_hijo || '.' || r.tabla_hija AS "message",
                            0 "state" FROM DUAL;
                        RETURN;
                END;
            END LOOP;
        
            OPEN p_cursor FOR SELECT p_id_archivo AS "uid", CONST.MSG_DELETE_OK
                AS "message", 1 "state" FROM DUAL;
        
        EXCEPTION
            WHEN OTHERS THEN
                v_errorCode := SQLCODE;
                v_errorMessage := SQLERRM;
                SELECT JSON_OBJECT(
                        'p_id_archivo' VALUE p_id_archivo,
                        'ora_code' VALUE v_errorCode,
                        'ora_msg' VALUE v_errorMessage,
                        'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB)
                INTO v_data
                FROM DUAL;
                PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_idLog);
                OPEN p_cursor FOR SELECT v_idLog AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorCode, v_errorMessage) AS "message",
                0 "state" FROM DUAL;
        END PROC_DELETE_HIJOS_EXTERNOS;


END PKG_GRL_ARCHIVO;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ARCHIVO_COMBINADO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ARCHIVO_COMBINADO" AS
    
    v_idApp NUMBER := CONST.APP_CGA;
    v_data CLOB;

PROCEDURE PROC_LISTAR_ARCHIVOS_CON_VERSIONES(p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
         SELECT a.ID_ARCHIVO                                      AS "archivoId",
               a.NOMBRE                                          AS "nombre",
               a.USUARIO                                         AS "usuario",
               a.ESTADO                                          AS "estadoArchivo",
               a.RUTA                                            AS "ruta",
               v.ID_VERSION                                      AS "versionId",
               v.ESTADO                                          AS "estadoVersion",
               TO_CHAR(v.FECHA_MODIFICACION, 'DD/MM/YYYY HH24:MI:SS') AS "fechaModificacion",
               v.METADATA                                        AS "metadata"
          FROM GRL_ARCHIVO a
          LEFT JOIN GRL_ARCHIVO_VERSION v
                 ON a.ID_ARCHIVO = v.ID_ARCHIVO
         ORDER BY a.ID_ARCHIVO,
                  v.ID_VERSION;
    END PROC_LISTAR_ARCHIVOS_CON_VERSIONES;

PROCEDURE PROC_OBTENER_ARCHIVO_Y_VERSION(
    p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
    p_proyecto  IN GRL_ARCHIVO.APP%TYPE,
    p_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT a.ID_ARCHIVO                                      AS "archivoId",
               a.NOMBRE                                          AS "nombre",
               a.USUARIO                                         AS "usuario",
               v.ID_VERSION                                      AS "versionId",
               TO_CHAR(v.FECHA_MODIFICACION, 'DD/MM/YYYY HH24:MI:SS') AS "fechaModificacion",
               v.METADATA                                        AS "metadata"
          FROM GRL_ARCHIVO a
          LEFT JOIN GRL_ARCHIVO_VERSION v
                 ON a.ID_ARCHIVO = v.ID_ARCHIVO
         WHERE a.ID_ARCHIVO = p_idArchivo
           AND a.APP = p_proyecto;
END PROC_OBTENER_ARCHIVO_Y_VERSION;

-- no se esta usando
PROCEDURE proc_delete_archivo_completo(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
        v_rows_archivo    NUMBER := 0;
        v_rows_version    NUMBER := 0;
    BEGIN
        -- Elimina l�gicamente el archivo
        UPDATE GRL_ARCHIVO
           SET estado = '0'
         WHERE id_archivo = p_id_archivo
           AND estado = '1';

        v_rows_archivo := SQL%ROWCOUNT; 

        -- Elimina l�gicamente todas sus versiones activas
        UPDATE GRL_ARCHIVO_VERSION
           SET estado = '0'
         WHERE id_archivo = p_id_archivo
           AND estado = '1';

        v_rows_version := SQL%ROWCOUNT;

        OPEN p_cursor FOR
            SELECT a.*, v.id_version, v.metadata, v.estado AS estado_version
              FROM GRL_ARCHIVO a
              LEFT JOIN GRL_ARCHIVO_VERSION v
                ON a.id_archivo = v.id_archivo
             WHERE a.id_archivo = p_id_archivo;

    EXCEPTION
        WHEN OTHERS THEN
                        v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_archivo' VALUE p_id_archivo,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;

    END proc_delete_archivo_completo;

PROCEDURE PROC_REPORTE_ESPACIO_POR_APP(
    p_app            IN GRL_ARCHIVO.APP%TYPE             DEFAULT NULL,
    p_estadoArchivo  IN GRL_ARCHIVO.ESTADO%TYPE          DEFAULT '1',
    p_estadoVersion  IN GRL_ARCHIVO_VERSION.ESTADO%TYPE  DEFAULT NULL,
    p_cursor         OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        WITH base AS (
            SELECT a.APP           AS app,
                   a.ID_ARCHIVO    AS archivoId,
                   v.ID_VERSION    AS versionId,
                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.tamano_bytes'
                       RETURNING NUMBER
                       DEFAULT 0 ON ERROR
                       NULL ON EMPTY
                   ) AS tamanoBytes
              FROM GRL_ARCHIVO a
              LEFT JOIN GRL_ARCHIVO_VERSION v
                     ON v.ID_ARCHIVO = a.ID_ARCHIVO
                    AND (
                            p_estadoVersion IS NULL
                            OR v.ESTADO = p_estadoVersion
                        )
             WHERE (
                       p_app IS NULL
                       OR a.APP = p_app
                   )
               AND (
                       p_estadoArchivo IS NULL
                       OR a.ESTADO = p_estadoArchivo
                   )
        ),
        fileStats AS (
            SELECT app,
                   archivoId,
                   COUNT(versionId) AS versionCount
              FROM base
             GROUP BY app,
                      archivoId
        ),
        appCounts AS (
            SELECT app,
                   SUM(CASE WHEN versionCount > 0 THEN 1 ELSE 0 END) AS archivosTotal,
                   SUM(CASE WHEN versionCount = 1 THEN 1 ELSE 0 END) AS archivosUnicos,
                   SUM(CASE WHEN versionCount > 1 THEN 1 ELSE 0 END) AS archivosMulti,
                   SUM(versionCount)                                 AS versionesCount
              FROM fileStats
             GROUP BY app
        ),
        appBytes AS (
            SELECT app,
                   SUM(NVL(tamanoBytes, 0)) AS bytesSum
              FROM base
             WHERE versionId IS NOT NULL
             GROUP BY app
        )
        SELECT ac.app              AS "proyecto",
               ac.archivosTotal    AS "archivosTotal",
               ac.archivosUnicos   AS "archivosUnicos",
               ac.archivosMulti    AS "archivosMulti",
               ac.versionesCount   AS "versionesCount",
               ab.bytesSum         AS "bytesSum",
               CASE
                   WHEN ab.bytesSum >= POWER(1024, 3)
                       THEN TO_CHAR(
                                ROUND(ab.bytesSum / POWER(1024, 3), 2),
                                'FM999990D00'
                            ) || ' GB'
                   ELSE
                       TO_CHAR(
                           ROUND(ab.bytesSum / POWER(1024, 2), 2),
                           'FM999990D00'
                       ) || ' MB'
               END                 AS "peso"
          FROM appCounts ac
          JOIN appBytes ab
            ON ab.app = ac.app
         ORDER BY ab.bytesSum DESC NULLS LAST;
END PROC_REPORTE_ESPACIO_POR_APP;

PROCEDURE PROC_ULTIMA_VERSION_ACTIVA_ALL(

        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
     OPEN p_cursor FOR
        SELECT archivoId          AS "archivoId",
               nombre             AS "nombre",
               usuario            AS "usuario",
               versionId          AS "versionId",
               ruta               AS "ruta",
               fechaModificacion  AS "fechaModificacion",
               metadata           AS "metadata"
          FROM (
                SELECT a.ID_ARCHIVO                                      AS archivoId,
                       a.NOMBRE                                          AS nombre,
                       a.USUARIO                                         AS usuario,
                       v.ID_VERSION                                      AS versionId,
                       a.RUTA                                            AS ruta,
                       TO_CHAR(v.FECHA_MODIFICACION, 'DD/MM/YYYY HH24:MI:SS') AS fechaModificacion,
                       v.METADATA                                        AS metadata,
                       ROW_NUMBER() OVER (
                           PARTITION BY a.ID_ARCHIVO
                           ORDER BY v.FECHA_MODIFICACION DESC,
                                    v.ID_VERSION DESC
                       ) AS rn
                  FROM GRL_ARCHIVO a
                  JOIN GRL_ARCHIVO_VERSION v
                    ON a.ID_ARCHIVO = v.ID_ARCHIVO
                 WHERE v.ESTADO = '1'
               )
         WHERE rn = 1;


    END PROC_ULTIMA_VERSION_ACTIVA_ALL;

PROCEDURE PROC_ULTIMA_VERSION_ACTIVA(
        p_id_archivo IN GRL_ARCHIVO.id_archivo%TYPE,
        p_proyecto IN GRL_ARCHIVO.app%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR
                SELECT a.id_archivo                                           AS "archivoID",
                       a.nombre                                               AS "nombre",
                       a.usuario                                              AS "usuario",
                       v.id_version                                           AS "versionId"  ,
                       TO_CHAR(v.fecha_modificacion, 'DD/MM/YYYY HH24:MI:SS') AS fecha_modificacion,
                       v.metadata
                FROM GRL_ARCHIVO a
                LEFT JOIN GRL_ARCHIVO_VERSION v
                       ON a.id_archivo = v.id_archivo
                WHERE v.estado = 1
                        AND a.id_archivo = p_id_archivo
                        AND a.app = p_proyecto
                ORDER BY v.fecha_modificacion DESC, v.id_version DESC
                FETCH FIRST 1 ROW ONLY;


    END PROC_ULTIMA_VERSION_ACTIVA;

PROCEDURE PROC_REPORTE_VERSIONES_POR_ARCHIVO(
    p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        WITH ver AS (
            SELECT a.ID_ARCHIVO AS archivoId,
                   a.APP AS proyecto,
                   a.NOMBRE AS nombreLogico,
                   a.USUARIO AS usuarioCreacionArchivo,
                   v.ID_VERSION AS versionId,
                   v.ESTADO AS estadoVersion,
                   v.FECHA_MODIFICACION AS fechaModificacion,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.nombre_archivo'
                       RETURNING VARCHAR2(4000)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS nombreArchivo,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.extension'
                       RETURNING VARCHAR2(50)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS extension,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.mime_type'
                       RETURNING VARCHAR2(100)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS mimeType,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.tamano_bytes'
                       RETURNING NUMBER
                       DEFAULT 0 ON ERROR
                       NULL ON EMPTY
                   ) AS tamanoBytes,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.fecha_creacion'
                       RETURNING VARCHAR2(30)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS fechaCreacionMeta,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.fecha_modificacion'
                       RETURNING VARCHAR2(30)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS fechaModificacionMeta,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.detalles.autor'
                       RETURNING VARCHAR2(4000)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS autorMeta
              FROM GRL_ARCHIVO a
              LEFT JOIN GRL_ARCHIVO_VERSION v
                     ON v.ID_ARCHIVO = a.ID_ARCHIVO
             WHERE a.ID_ARCHIVO = p_idArchivo
        ),
        rn AS (
            SELECT archivoId,
                   proyecto,
                   nombreLogico,
                   usuarioCreacionArchivo,
                   versionId,
                   estadoVersion,
                   fechaModificacion,
                   nombreArchivo,
                   extension,
                   mimeType,
                   tamanoBytes,
                   fechaCreacionMeta,
                   fechaModificacionMeta,
                   autorMeta,
                   ROW_NUMBER() OVER (
                       PARTITION BY archivoId
                       ORDER BY fechaModificacion ASC,
                                versionId ASC
                   ) AS rnAsc,
                   ROW_NUMBER() OVER (
                       PARTITION BY archivoId
                       ORDER BY fechaModificacion DESC,
                                versionId DESC
                   ) AS rnDesc
              FROM ver
        )
        SELECT archivoId AS archivoId,
               proyecto AS proyecto,
               nombreLogico AS nombreLogico,
               versionId AS versionId,
               estadoVersion AS estadoVersion,
               CASE estadoVersion
                   WHEN '1' THEN 'ACTIVA'
                   ELSE 'INACTIVA'
               END AS estadoVersionTexto,
               TO_CHAR(fechaModificacion, 'DD/MM/YYYY HH24:MI:SS') AS fechaModificacion,
               COALESCE(autorMeta, usuarioCreacionArchivo) AS usuarioResponsable,
               CASE
                   WHEN rnAsc = 1 THEN 'CREACI�N'
                   ELSE 'ACTUALIZACI�N'
               END AS accion,
               nombreArchivo AS nombreArchivo,
               extension AS extension,
               mimeType AS mimeType,
               tamanoBytes AS bytes,
               CASE
                   WHEN NVL(tamanoBytes, 0) >= POWER(1024, 3)
                       THEN TO_CHAR(
                                ROUND(tamanoBytes / POWER(1024, 3), 2),
                                'FM999990D00'
                            ) || ' GB'
                   WHEN NVL(tamanoBytes, 0) >= POWER(1024, 2)
                       THEN TO_CHAR(
                                ROUND(tamanoBytes / POWER(1024, 2), 2),
                                'FM999990D00'
                            ) || ' MB'
                   ELSE
                       TO_CHAR(NVL(tamanoBytes, 0)) || ' B'
               END AS peso,
               fechaCreacionMeta AS fechaCreacionMetadata,
               fechaModificacionMeta AS fechaModificacionMetadata
          FROM rn
         ORDER BY fechaModificacion DESC NULLS LAST,
                  versionId DESC;
END PROC_REPORTE_VERSIONES_POR_ARCHIVO;

PROCEDURE PROC_ARCHIVO_MULT_VERSIONES(
            p_proyecto  IN GRL_ARCHIVO.app%TYPE,
            p_cursor     OUT SYS_REFCURSOR
        )AS
    BEGIN
        OPEN p_cursor FOR
            SELECT a.id_archivo,
                   a.nombre,
                   a.usuario,
                   v.id_version,
                   v.fecha_modificacion,
                   v.metadata
            FROM GRL_ARCHIVO a
            INNER JOIN GRL_ARCHIVO_VERSION v
                   ON a.id_archivo = v.id_archivo
            WHERE v.estado = 1
                  AND (a.app = p_proyecto OR p_proyecto IS NULL)
                  AND a.id_archivo IN (
                      SELECT v2.id_archivo
                      FROM GRL_ARCHIVO_VERSION v2
                      WHERE v2.estado = 1
                      GROUP BY v2.id_archivo
                      HAVING COUNT(*) > 1
                  )
            ORDER BY a.id_archivo, v.fecha_modificacion DESC, v.id_version DESC;
    END PROC_ARCHIVO_MULT_VERSIONES;   

PROCEDURE PROC_REPORTE_LIMPIEZA_SUGERIDA(
    p_app            IN GRL_ARCHIVO.APP%TYPE             DEFAULT NULL,
    p_diasInactivo   IN NUMBER                           DEFAULT 365,
    p_estadoArchivo  IN GRL_ARCHIVO.ESTADO%TYPE          DEFAULT NULL,
    p_estadoVersion  IN GRL_ARCHIVO_VERSION.ESTADO%TYPE  DEFAULT NULL,
    p_cursor         OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        WITH versionBase AS (
            SELECT a.ID_ARCHIVO AS archivoId,
                   a.APP AS proyecto,
                   a.NOMBRE AS nombreLogico,
                   a.ESTADO AS estadoArchivo,
                   v.ID_VERSION AS versionId,
                   v.ESTADO AS estadoVersion,
                   v.FECHA_MODIFICACION AS fechaModificacion,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.nombre_archivo'
                       RETURNING VARCHAR2(4000)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS nombreArchivo,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.mime_type'
                       RETURNING VARCHAR2(200)
                       NULL ON ERROR
                       NULL ON EMPTY
                   ) AS mimeType,

                   JSON_VALUE(
                       v.METADATA FORMAT JSON,
                       '$.tamano_bytes'
                       RETURNING NUMBER
                       DEFAULT 0 ON ERROR
                       NULL ON EMPTY
                   ) AS tamanoBytes
              FROM GRL_ARCHIVO a
              LEFT JOIN GRL_ARCHIVO_VERSION v
                     ON v.ID_ARCHIVO = a.ID_ARCHIVO
             WHERE (
                       p_app IS NULL
                       OR a.APP = p_app
                       OR a.APP IS NULL
                   )
               AND (
                       p_estadoArchivo IS NULL
                       OR a.ESTADO = p_estadoArchivo
                   )
               AND (
                       p_estadoVersion IS NULL
                       OR v.ESTADO = p_estadoVersion
                   )
        ),
        agg AS (
            SELECT archivoId,
                   MAX(fechaModificacion) AS maxMod,
                   MAX(CASE WHEN estadoVersion = '1' THEN 1 ELSE 0 END) AS hayActiva
              FROM versionBase
             GROUP BY archivoId
        ),
        firmas AS (
            SELECT archivoId,
                   LOWER(TRIM(nombreArchivo)) AS nombreArchivoNorm,
                   LOWER(TRIM(mimeType)) AS mimeTypeNorm,
                   NVL(tamanoBytes, 0) AS bytesNorm
              FROM (
                    SELECT archivoId,
                           nombreArchivo,
                           mimeType,
                           tamanoBytes,
                           ROW_NUMBER() OVER (
                               PARTITION BY archivoId
                               ORDER BY fechaModificacion DESC NULLS LAST,
                                        versionId DESC
                           ) AS rn
                      FROM versionBase
                   )
             WHERE rn = 1
        ),
        gruposDup AS (
            SELECT nombreArchivoNorm,
                   mimeTypeNorm,
                   bytesNorm,
                   COUNT(*) AS cantidad
              FROM firmas
             GROUP BY nombreArchivoNorm,
                      mimeTypeNorm,
                      bytesNorm
            HAVING COUNT(*) > 1
        ),
        dupMarca AS (
            SELECT f.archivoId,
                   f.nombreArchivoNorm,
                   f.mimeTypeNorm,
                   f.bytesNorm,
                   g.cantidad,
                   ROW_NUMBER() OVER (
                       PARTITION BY f.nombreArchivoNorm,
                                    f.mimeTypeNorm,
                                    f.bytesNorm
                       ORDER BY (
                           SELECT a.maxMod
                             FROM agg a
                            WHERE a.archivoId = f.archivoId
                       ) DESC
                   ) AS rnGrupo
              FROM firmas f
              JOIN gruposDup g
                ON g.nombreArchivoNorm = f.nombreArchivoNorm
               AND g.mimeTypeNorm = f.mimeTypeNorm
               AND g.bytesNorm = f.bytesNorm
        ),
        inactivos AS (
            SELECT a.archivoId,
                   'INACTIVO' AS categoria,
                   'Sin actividad por m�s de ' || p_diasInactivo || ' d�as' AS razon,
                   a.maxMod AS fechaRelevante
              FROM agg a
             WHERE a.maxMod IS NOT NULL
               AND a.maxMod < (SYSDATE - p_diasInactivo)
        ),
        sinActivas AS (
            SELECT a.archivoId,
                   'SIN_ACTIVAS' AS categoria,
                   'Sin versiones activas' AS razon,
                   a.maxMod AS fechaRelevante
              FROM agg a
             WHERE NVL(a.hayActiva, 0) = 0
        ),
        duplicados AS (
            SELECT d.archivoId,
                   'DUPLICADO' AS categoria,
                   'Duplicado de firma: nombre=' || COALESCE(d.nombreArchivoNorm, '(s/n)') ||
                   ', mime=' || COALESCE(d.mimeTypeNorm, '(s/n)') ||
                   ', bytes=' || TO_CHAR(d.bytesNorm) AS razon,
                   (
                       SELECT a.maxMod
                         FROM agg a
                        WHERE a.archivoId = d.archivoId
                   ) AS fechaRelevante
              FROM dupMarca d
             WHERE d.rnGrupo > 1
        ),
        base AS (
            SELECT archivoId,
                   categoria,
                   razon,
                   fechaRelevante
              FROM inactivos

            UNION ALL

            SELECT archivoId,
                   categoria,
                   razon,
                   fechaRelevante
              FROM sinActivas

            UNION ALL

            SELECT archivoId,
                   categoria,
                   razon,
                   fechaRelevante
              FROM duplicados
        ),
        ult AS (
            SELECT x.archivoId,
                   MAX(x.fechaModificacion) AS maxMod
              FROM versionBase x
             GROUP BY x.archivoId
        )
        SELECT base.archivoId AS "archivoId",
               v2.proyecto AS "proyecto",
               v2.nombreLogico AS "nombreLogico",
               v2.nombreArchivo AS "nombreArchivo",
               v2.mimeType AS "mimeType",
               v2.tamanoBytes AS "bytes",
               CASE
                   WHEN NVL(v2.tamanoBytes, 0) >= POWER(1024, 3)
                       THEN TO_CHAR(
                                ROUND(v2.tamanoBytes / POWER(1024, 3), 2),
                                'FM999990D00'
                            ) || ' GB'
                   WHEN NVL(v2.tamanoBytes, 0) >= POWER(1024, 2)
                       THEN TO_CHAR(
                                ROUND(v2.tamanoBytes / POWER(1024, 2), 2),
                                'FM999990D00'
                            ) || ' MB'
                   ELSE
                       TO_CHAR(NVL(v2.tamanoBytes, 0)) || ' B'
               END AS "peso",
               base.categoria AS "categoria",
               base.razon AS "razon",
               TO_CHAR(base.fechaRelevante, 'DD/MM/YYYY HH24:MI:SS') AS "fechaRelevante"
          FROM base
          LEFT JOIN ult
                 ON ult.archivoId = base.archivoId
          LEFT JOIN versionBase v2
                 ON v2.archivoId = base.archivoId
                AND v2.fechaModificacion = ult.maxMod
         ORDER BY base.categoria,
                  base.fechaRelevante DESC NULLS LAST,
                  base.archivoId;
END PROC_REPORTE_LIMPIEZA_SUGERIDA;

PROCEDURE PROC_REPORTE_ACTIVIDAD_USUARIOS(
    p_app     IN GRL_ARCHIVO.APP%TYPE DEFAULT NULL,
    p_topN    IN NUMBER DEFAULT 10,
    p_cursor  OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        WITH act AS (
            SELECT v.ID_ARCHIVO AS archivoId,

                   SUM(
                       NVL(
                           JSON_VALUE(
                               v.METADATA FORMAT JSON,
                               '$.tamano_bytes'
                               RETURNING NUMBER
                               DEFAULT 0 ON ERROR
                           ),
                           0
                       )
                   ) AS bytesTodasVersiones,

                   MAX(
                       CASE
                           WHEN v.ESTADO = '1' THEN
                               NVL(
                                   JSON_VALUE(
                                       v.METADATA FORMAT JSON,
                                       '$.tamano_bytes'
                                       RETURNING NUMBER
                                       DEFAULT 0 ON ERROR
                                   ),
                                   0
                               )
                       END
                   ) AS bytesActuales,

                   COUNT(*) AS versionesTotales
              FROM GRL_ARCHIVO_VERSION v
             GROUP BY v.ID_ARCHIVO
        ),
        base AS (
            SELECT a.ID_ARCHIVO AS archivoId,
                   NVL(NULLIF(TRIM(a.USUARIO), ''), 'SIN_USUARIO') AS usuario,
                   act.bytesActuales AS bytesActuales,
                   act.bytesTodasVersiones AS bytesTodasVersiones,
                   act.versionesTotales AS versionesTotales
              FROM GRL_ARCHIVO a
              LEFT JOIN act
                     ON act.archivoId = a.ID_ARCHIVO
             WHERE (
                       p_app IS NULL
                       OR a.APP = p_app
                   )
        ),
        aggr AS (
            SELECT usuario AS usuario,
                   COUNT(*) AS archivosSubidos,
                   NVL(SUM(bytesActuales), 0) AS bytesActuales,
                   NVL(SUM(bytesTodasVersiones), 0) AS bytesTodasVersiones,
                   NVL(SUM(versionesTotales), 0) AS versionesTotales
              FROM base
             GROUP BY usuario
        ),
        ranked AS (
            SELECT usuario AS usuario,
                   archivosSubidos AS archivosSubidos,
                   versionesTotales AS versionesTotales,
                   bytesActuales AS bytesActuales,
                   bytesTodasVersiones AS bytesTodasVersiones,
                   archivosSubidos + versionesTotales AS puntajeActividad,
                   ROW_NUMBER() OVER (
                       ORDER BY archivosSubidos + versionesTotales DESC,
                                bytesActuales DESC
                   ) AS rn
              FROM aggr
        )
        SELECT usuario AS "usuario",
               archivosSubidos AS "archivosSubidos",
               versionesTotales AS "versionesTotales",
               bytesActuales AS "bytesActuales",
               bytesTodasVersiones AS "bytesTodasVersiones",
               puntajeActividad AS "puntajeActividad"
          FROM ranked
         WHERE rn <= NVL(p_topN, 10)
         ORDER BY rn;
END PROC_REPORTE_ACTIVIDAD_USUARIOS;

PROCEDURE PROC_REPORTE_EVOLUCION_MENSUAL(
    p_app          IN  GRL_ARCHIVO.APP%TYPE DEFAULT NULL,
    p_fechaInicio  IN  DATE                 DEFAULT NULL,
    p_fechaFin     IN  DATE                 DEFAULT NULL,
    p_cursor       OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        WITH params AS (
            SELECT p_app AS app,
                   p_fechaInicio AS fechaInicio,
                   p_fechaFin AS fechaFin
              FROM DUAL
        ),
        bounds AS (
            SELECT TRUNC(
                       COALESCE(p.fechaInicio, MIN(v.FECHA_MODIFICACION)),
                       'MM'
                   ) AS mesInicio,
                   ADD_MONTHS(
                       TRUNC(
                           COALESCE(p.fechaFin, MAX(v.FECHA_MODIFICACION)),
                           'MM'
                       ),
                       1
                   ) AS mesFin
              FROM GRL_ARCHIVO a
              JOIN GRL_ARCHIVO_VERSION v
                ON v.ID_ARCHIVO = a.ID_ARCHIVO
              CROSS JOIN params p
             WHERE (
                       p.app IS NULL
                       OR a.APP = p.app
                   )
               AND (
                       p.fechaInicio IS NULL
                       OR v.FECHA_MODIFICACION >= p.fechaInicio
                   )
               AND (
                       p.fechaFin IS NULL
                       OR v.FECHA_MODIFICACION < p.fechaFin + 1
                   )
        ),
        months AS (
            SELECT ADD_MONTHS(b.mesInicio, LEVEL - 1) AS mesInicio
              FROM bounds b
           CONNECT BY ADD_MONTHS(b.mesInicio, LEVEL - 1) < b.mesFin
        ),
        data AS (
            SELECT TRUNC(v.FECHA_MODIFICACION, 'MM') AS mesInicio,
                   COUNT(v.ID_VERSION) AS cantidad,
                   SUM(
                       NVL(
                           JSON_VALUE(
                               v.METADATA FORMAT JSON,
                               '$.tamano_bytes'
                               RETURNING NUMBER
                               DEFAULT 0 ON ERROR
                               NULL ON EMPTY
                           ),
                           0
                       )
                   ) AS bytesTotal
              FROM GRL_ARCHIVO a
              JOIN GRL_ARCHIVO_VERSION v
                ON v.ID_ARCHIVO = a.ID_ARCHIVO
              CROSS JOIN params p
             WHERE (
                       p.app IS NULL
                       OR a.APP = p.app
                   )
               AND (
                       p.fechaInicio IS NULL
                       OR v.FECHA_MODIFICACION >= p.fechaInicio
                   )
               AND (
                       p.fechaFin IS NULL
                       OR v.FECHA_MODIFICACION < p.fechaFin + 1
                   )
             GROUP BY TRUNC(v.FECHA_MODIFICACION, 'MM')
        )
        SELECT EXTRACT(YEAR FROM m.mesInicio) AS "anio",
               TO_CHAR(m.mesInicio, 'MM') AS "mesNumero",
               TRIM(
                   TO_CHAR(
                       m.mesInicio,
                       'FMMonth',
                       'NLS_DATE_LANGUAGE=SPANISH'
                   )
               ) AS "mes",
               NVL(d.cantidad, 0) AS "cantidad",
               NVL(d.bytesTotal, 0) AS "bytesTotal",
               ROUND(NVL(d.bytesTotal, 0) / POWER(1024, 2), 2) AS "mbTotal",
               ROUND(NVL(d.bytesTotal, 0) / POWER(1024, 3), 2) AS "gbTotal"
          FROM months m
          LEFT JOIN data d
                 ON d.mesInicio = m.mesInicio
         ORDER BY m.mesInicio;
END PROC_REPORTE_EVOLUCION_MENSUAL;



    PROCEDURE INFO_FILE_FOR_DELETE(
        p_idArchivo IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor       OUT SYS_REFCURSOR
    ) as
     BEGIN
  OPEN p_cursor FOR   
        SELECT 
        A.id_archivo        AS "id",
        A.NOMBRE            AS "nombre",
        A.APP               AS "aplicacion",
        A.RUTA              AS "ruta",
        av.id_version       AS "version", 
        av.metadata         AS "data" 
        from GRL_ARCHIVO A
        LEFT JOIN GRL_ARCHIVO_VERSION AV ON A.id_archivo = AV.id_archivo
        where A.id_archivo =p_idArchivo;

     END INFO_FILE_FOR_DELETE;


    PROCEDURE FILE_DELETE_MASTER(
        p_idArchivo     IN GRL_ARCHIVO.ID_ARCHIVO%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) AS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
        v_state        NUMBER;
        v_uid          NUMBER;
        v_message      VARCHAR2(4000);
        v_valida       NUMBER;
    BEGIN

    -- 1. (Opcional) Borrar hijos de otros esquemas � ver PROC_DELETE_HIJOS_EXTERNOS m�s abajo
        PKG_GRL_ARCHIVO.PROC_DELETE_HIJOS_EXTERNOS(p_idArchivo, p_cursor);
            FETCH p_cursor INTO v_uid, v_message, v_state;
            CLOSE p_cursor;

        IF v_state = 0 THEN
            OPEN p_cursor FOR SELECT v_uid AS "uid", v_message AS "message", 0 "state" FROM DUAL;
            RETURN;
        END IF;

            -- 2. Borrar hijos conocidos (versiones)
    PKG_GRL_ARCHIVO_VERSION.PROC_DELETE_VERSION_IDARCHIVO(p_idArchivo,
                                                                p_cursor);

    FETCH p_cursor INTO v_uid, v_message, v_state;
    CLOSE p_cursor;

    IF v_state = 0 THEN
        -- Propaga el error tal cual vino de PROC_DELETE_VERSION, no contin�a
        OPEN p_cursor FOR SELECT v_uid AS "uid", v_message AS "message", 0 "state" FROM DUAL;
        RETURN;
    END IF;

    -- 3. Borrar el archivo padre                                      
        PKG_GRL_ARCHIVO.PROC_DELETE_ARCHIVO(  p_idArchivo,
                                              p_cursor);
        select count(1) into v_valida
        from GRL_ARCHIVO
        where ID_ARCHIVO = p_idArchivo;

        IF v_valida > 0 then
            RAISE_APPLICATION_ERROR(CONST.ERROR_DEPENDENCIA, CONST.MSG_ERROR_INESPERADO);
        END IF;

 EXCEPTION
    WHEN OTHERS THEN
        v_errorCode := SQLCODE;
        v_errorMessage := SQLERRM;
        SELECT JSON_OBJECT(
                       'p_idArchivo' VALUE p_idArchivo,
                       'ora_code' VALUE v_errorCode,
                       'ora_msg' VALUE v_errorMessage,
                       'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                       RETURNING CLOB)
        INTO v_data
        FROM DUAL;

        PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
        OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
        0 "state" FROM DUAL;
    END FILE_DELETE_MASTER;

END PKG_GRL_ARCHIVO_COMBINADO;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ARCHIVO_VERSION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ARCHIVO_VERSION" AS

    v_idApp NUMBER := CONST.APP_CGA;
    v_data CLOB;

    PROCEDURE PROC_INSERT_VERSION(
        p_id_archivo IN GRL_ARCHIVO_VERSION.id_archivo%TYPE,
        p_estado IN GRL_ARCHIVO_VERSION.estado%TYPE,
        p_metadata IN CLOB,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_id NUMBER;
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        INSERT INTO GRL_ARCHIVO_VERSION (id_archivo, estado, metadata)
        VALUES (p_id_archivo, p_estado, p_metadata)
        RETURNING id_version INTO v_id;

        OPEN p_cursor FOR SELECT v_id AS "uid", CONST.MSG_INSERT_OK 
        AS "message", 1 "state"  FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_archivo' VALUE p_id_archivo,
                           'p_estado' VALUE p_estado,
                           'p_metadata' VALUE p_metadata,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
    END PROC_INSERT_VERSION;






    PROCEDURE PROC_UPDATE_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_estado IN GRL_ARCHIVO_VERSION.estado%TYPE,
        p_metadata IN CLOB,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        UPDATE GRL_ARCHIVO_VERSION
        SET estado = p_estado,
            metadata = p_metadata
        WHERE id_version = p_id_version;

        IF SQL%ROWCOUNT = 0 THEN
            OPEN p_cursor FOR
                SELECT p_id_version AS "uid",
                       CONST.MSG_NO_ROWS_AFFECTED AS "message",
                       1 AS "state"
                  FROM DUAL;
        ELSE
            OPEN p_cursor FOR SELECT p_id_version AS "uid",CONST.MSG_UPDATE_OK 
            AS "message", 1 "state" FROM DUAL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
                        v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_version' VALUE p_id_version,
                           'p_estado' VALUE p_estado,
                           'p_metadata' VALUE p_metadata,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

          PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
          OPEN p_cursor FOR SELECT v_idLog  AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message",
            0 "state" FROM DUAL;

    END PROC_UPDATE_VERSION;





    PROCEDURE PROC_DELETE_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        DELETE FROM GRL_ARCHIVO_VERSION WHERE id_version = p_id_version;

                OPEN p_cursor FOR SELECT p_id_version AS "uid",CONST.MSG_DELETE_OK 
        AS "message", 1 "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
                v_errorMessage := SQLERRM;
                SELECT JSON_OBJECT(
                               'p_id_version' VALUE p_id_version,
                               'ora_code' VALUE v_errorCode,
                               'ora_msg' VALUE v_errorMessage,
                               'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               RETURNING CLOB)
                INTO v_data
                FROM DUAL; 

                PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
                OPEN p_cursor FOR SELECT v_idLog  AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message",
                0 "state" FROM DUAL;
    END PROC_DELETE_VERSION;



    PROCEDURE PROC_SELECT_VERSION(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR SELECT    ID_VERSION,
                                    ID_ARCHIVO,
                                    FECHA_MODIFICACION,
                                    ESTADO,
                                    METADATA
        FROM GRL_ARCHIVO_VERSION WHERE id_version = p_id_version;

    END PROC_SELECT_VERSION;




    PROCEDURE PROC_LIST_VERSIONES(
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR SELECT ID_VERSION,
                                    ID_ARCHIVO,
                                    FECHA_MODIFICACION,
                                    ESTADO,
                                    METADATA
                        FROM GRL_ARCHIVO_VERSION;
    END PROC_LIST_VERSIONES;



  PROCEDURE proc_delete_archivo_version_V2(
        p_id_version IN GRL_ARCHIVO_VERSION.id_version%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        UPDATE GRL_ARCHIVO_VERSION
           SET estado = '0'
         WHERE id_version = p_id_version
           AND estado = '1';



        IF SQL%ROWCOUNT = 0 THEN
            OPEN p_cursor FOR
                SELECT p_id_version AS "uid",
                       CONST.MSG_NO_ROWS_AFFECTED AS "message",
                       1 AS "state"
                  FROM DUAL;
        ELSE
            OPEN p_cursor FOR SELECT p_id_version AS "uid",CONST.MSG_UPDATE_OK 
            AS "message", 1 "state" FROM DUAL;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN

            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_version' VALUE p_id_version,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

          PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
          OPEN p_cursor FOR SELECT v_idLog  AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message",
            0 "state" FROM DUAL;


    END proc_delete_archivo_version_V2;




  PROCEDURE proc_delete_update_masivo(
        p_id_archivo IN GRL_ARCHIVO_VERSION.id_archivo%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        UPDATE GRL_ARCHIVO_VERSION
           SET estado = '0'
         WHERE id_archivo = p_id_archivo
           AND estado = '1';

       -- COMMIT;

        IF SQL%ROWCOUNT = 0 THEN
            OPEN p_cursor FOR
                SELECT p_id_archivo AS "uid",
                       CONST.MSG_NO_ROWS_AFFECTED AS "message",
                       1 AS "state"
                  FROM DUAL;
        ELSE
            OPEN p_cursor FOR SELECT p_id_archivo AS "uid",CONST.MSG_UPDATE_OK 
            AS "message", 1 "state" FROM DUAL;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            --ROLLBACK;
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_archivo' VALUE p_id_archivo,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
    END proc_delete_update_masivo;




 PROCEDURE proc_activar_archivo (
   p_id_archivo IN  GRL_ARCHIVO_VERSION.id_archivo%TYPE,
   p_id_version IN  GRL_ARCHIVO_VERSION.id_version%TYPE,
   p_cursor     OUT SYS_REFCURSOR
) IS
   v_estado NUMBER;
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
BEGIN
   -- 0) Validar que la versi�n exista y pertenezca al archivo; obtener su estado actual
   SELECT estado
     INTO v_estado
     FROM GRL_ARCHIVO_VERSION
    WHERE id_archivo = p_id_archivo
      AND id_version = p_id_version;

   -- 0.1) Si ya est� activa, no hacer nada y retornar mensaje
   IF v_estado = 1 THEN
      OPEN p_cursor FOR
         SELECT p_id_archivo as "uid",'Ya esta activado el archivo' AS "message", 1 as "state" from dual;
      RETURN;
   END IF;

   -- 1) Actualizar estados (desactivar otras y activar la solicitada)
   --SAVEPOINT sp_before;

   UPDATE GRL_ARCHIVO_VERSION
      SET estado = 0
    WHERE id_archivo = p_id_archivo
      AND estado = 1;  -- desactiva solo las activas

   UPDATE GRL_ARCHIVO_VERSION
      SET estado = 1,
          fecha_modificacion = SYSDATE
    WHERE id_archivo = p_id_archivo
      AND id_version = p_id_version;

            IF SQL%ROWCOUNT = 0 THEN
                OPEN p_cursor FOR
                    SELECT p_id_archivo AS "uid",
                           'No se actualiz� ning�n registro.' AS "message",
                           1 AS "state"
                      FROM DUAL;
            ELSE
                OPEN p_cursor FOR SELECT p_id_archivo AS "uid",CONST.MSG_UPDATE_OK 
                AS "message", 1 "state" FROM DUAL;
            END IF;

EXCEPTION
WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                           'p_id_archivo' VALUE p_id_archivo,
                           'p_id_version' VALUE p_id_version,
                           'ora_code' VALUE v_errorCode,
                           'ora_msg' VALUE v_errorMessage,
                           'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                           RETURNING CLOB)
            INTO v_data
            FROM DUAL;

            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
            OPEN p_cursor FOR SELECT v_idLog  AS "uid", CONST.MSG_ERROR_INESPERADO AS "message",
            0 "state" FROM DUAL;
END proc_activar_archivo;

PROCEDURE PROC_DELETE_VERSION_IDARCHIVO(
        p_id_archivo IN GRL_ARCHIVO_VERSION.ID_ARCHIVO%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) AS
        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(4000);
        v_idLog        NUMBER;
    BEGIN
        DELETE FROM GRL_ARCHIVO_VERSION WHERE ID_ARCHIVO = p_id_archivo;

                OPEN p_cursor FOR SELECT p_id_archivo AS "uid",CONST.MSG_DELETE_OK 
        AS "message", 1 "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
                v_errorMessage := SQLERRM;
                SELECT JSON_OBJECT(
                               'p_id_archivo' VALUE p_id_archivo,
                               'ora_code' VALUE v_errorCode,
                               'ora_msg' VALUE v_errorMessage,
                               'backtrace' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               RETURNING CLOB)
                INTO v_data
                FROM DUAL; 

                PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR,v_data,v_idLog);
                OPEN p_cursor FOR SELECT v_idLog  AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message",
                0 "state" FROM DUAL;
    END PROC_DELETE_VERSION_IDARCHIVO;



END PKG_GRL_ARCHIVO_VERSION;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ATRIBUTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ATRIBUTO" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_atributo
-- PURPOSE:    Package para las funciones CRUD de los atributos que se pueden asociar a una estruturas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_atributo
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app        NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    const_Atributo_VIGENTE    NUMBER    := 73;
    const_Atributo_NO_VIGENTE NUMBER    := 74;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
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
    ) IS

    v_id               grl_atributo.id_atributo%TYPE    := 0;
    v_id_componente    grl_atributo.id_componente%TYPE  := p_id_componente; 
    v_nombre           grl_atributo.nombre%TYPE         := upper(trim(p_nombre)); 
    v_id_tipo_dato     grl_atributo.id_componente%TYPE  := p_id_tipo_dato;
    v_largo            grl_atributo.largo%TYPE          := p_largo;
    v_posicion         grl_atributo.posicion%TYPE       := p_posicion;
    v_id_estado        grl_atributo.id_estado%TYPE      := p_id_estado;
    v_objeto           grl_atributo.objeto%TYPE         := p_objeto;
    v_id_columna       grl_atributo.columna_id%TYPE     := p_id_columna;
    v_columna_data     grl_atributo.columna_data%TYPE   := p_columna_data;
    v_obligatorio      grl_atributo.obligatorio%TYPE    := p_obligatorio;
    v_valor_default    grl_atributo.valor_default%TYPE  := p_valor_default;
    v_mascara          grl_atributo.mascara%TYPE        := p_mascara;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_componente', v_id_componente, 'required|int'),
                VALIDATOR.RULE('v_nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('v_id_tipo_dato', v_id_tipo_dato, 'required|int'),
                VALIDATOR.RULE('v_largo', v_largo, 'int'),
                VALIDATOR.RULE('v_posicion', v_posicion, 'int'),
                VALIDATOR.RULE('v_id_estado', v_id_estado, 'required|int'),
                VALIDATOR.RULE('v_objeto', v_objeto, 'string'),
                VALIDATOR.RULE('v_id_columna', v_id_columna, 'string'),
                VALIDATOR.RULE('v_columna_data', v_columna_data, 'string'),
                VALIDATOR.RULE('v_obligatorio', v_obligatorio, 'string'),
                VALIDATOR.RULE('v_valor_default', v_valor_default, 'string'),
                VALIDATOR.RULE('v_mascara', v_mascara, 'string')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,30)) THEN
            v_nombre := substr(v_nombre,1,30);
        end if;

        SELECT grl_estructuras_seq.NEXTVAL INTO v_id FROM dual;

        INSERT INTO grl_atributo (id_atributo, id_componente, nombre, id_tipo_dato, largo, posicion, id_estado, objeto, columna_id, columna_data, obligatorio, valor_default, mascara)
        VALUES (v_id, v_id_componente, v_nombre, v_id_tipo_dato, v_largo, v_posicion, v_id_estado, v_objeto, v_id_columna, v_columna_data, v_obligatorio, v_valor_default, v_mascara);

        v_rows := SQL%ROWCOUNT;
        
        IF v_rows > 0 THEN
           COMMIT;
           pkg_estructura_negocio.Propaga_atributo(v_id, p_cursor);
           OPEN p_cursor FOR
                SELECT v_id id, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", 0 id, 'Error al momento de registrar un atributo, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_id,
                    'v_id_componente'  VALUE v_id_componente,
                    'v_nombre'         VALUE v_nombre,
                    'v_id_tipo_dato'   VALUE v_id_tipo_dato,
                    'v_largo'          VALUE v_largo,
                    'v_posicion'       VALUE v_posicion,
                    'v_id_estado'      VALUE v_id_estado,
                    'v_objeto'         VALUE v_objeto,
                    'v_columna_id'     VALUE v_id_columna,
                    'v_columna_data'   VALUE v_columna_data,
                    'v_obligatorio'    VALUE v_obligatorio,
                    'v_valor_default'  VALUE v_valor_default,
                    'v_mascara'        VALUE v_mascara,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Insert_Atributo;


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
    ) IS

    v_p_id_atributo    grl_atributo.id_componente%TYPE     := p_id_atributo;
    v_id_componente    grl_atributo.id_componente%TYPE     := p_id_componente; 
    v_nombre           grl_atributo.nombre%TYPE            := upper(trim(p_nombre)); 
    v_id_tipo_dato     grl_atributo.id_componente%TYPE     := p_id_tipo_dato;
    v_largo            grl_atributo.largo%TYPE             := p_largo;
    v_posicion         grl_atributo.posicion%TYPE          := p_posicion;
    v_id_estado        grl_atributo.id_estado%TYPE         := p_id_estado;
    v_objeto           grl_atributo.objeto%TYPE            := p_objeto;
    v_id_columna       grl_atributo.columna_id%TYPE        := p_id_columna;
    v_columna_data     grl_atributo.columna_data%TYPE      := p_columna_data;
    v_obligatorio      grl_atributo.obligatorio%TYPE       := p_obligatorio;
    v_valor_default    grl_atributo.valor_default%TYPE     := p_valor_default;
    v_mascara          grl_atributo.mascara%TYPE        := p_mascara;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_p_id_atributo', v_p_id_atributo, 'required|int'),
                VALIDATOR.RULE('v_id_componente', v_id_componente, 'required|int'),
                VALIDATOR.RULE('v_nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('v_id_tipo_dato', v_id_tipo_dato, 'required|int'),
                VALIDATOR.RULE('v_largo', v_largo, 'int'),
                VALIDATOR.RULE('v_posicion', v_posicion, 'int'),
                VALIDATOR.RULE('v_id_estado', v_id_estado, 'required|int'),
                VALIDATOR.RULE('v_objeto', v_objeto, 'string'),
                VALIDATOR.RULE('v_id_columna', v_id_columna, 'string'),
                VALIDATOR.RULE('v_columna_data', v_columna_data, 'string'),
                VALIDATOR.RULE('v_obligatorio', v_obligatorio, 'string'),
                VALIDATOR.RULE('v_valor_default', v_valor_default, 'string'),
                VALIDATOR.RULE('v_mascara', v_mascara, 'string')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,30)) THEN
            v_nombre := substr(v_nombre,1,30);
        end if;

        UPDATE grl_atributo 
        SET     id_componente = v_id_componente, 
                nombre = v_nombre,
                id_tipo_dato = v_id_tipo_dato,
                largo = v_largo, 
                posicion = v_posicion, 
                id_estado = v_id_estado, 
                objeto = v_objeto, 
                columna_id = v_id_columna, 
                columna_data = v_columna_data, 
                obligatorio = v_obligatorio, 
                valor_default = v_valor_default,
                mascara = v_mascara
        WHERE id_atributo = v_p_id_atributo;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_p_id_atributo id, CONST.MSG_UPDATE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", 0 id, 'Error al momento de actualizar un atributo, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_p_id_atributo,
                    'v_id_componente'       VALUE v_id_componente,
                    'v_nombre'         VALUE v_nombre,
                    'v_id_tipo_dato'   VALUE v_id_tipo_dato,
                    'v_largo'          VALUE v_largo,
                    'v_posicion'       VALUE v_posicion,
                    'v_id_estado'      VALUE v_id_estado,
                    'v_objeto'         VALUE v_objeto,
                    'v_columna_id'     VALUE v_id_columna,
                    'v_columna_data'   VALUE v_columna_data,
                    'v_obligatorio'    VALUE v_obligatorio,
                    'v_valor_default'  VALUE v_valor_default,
                    'v_mascara'        VALUE v_mascara,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Update_Atributo;


PROCEDURE Delete_Atributo (
        p_id_atributo       IN grl_atributo.id_atributo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_p_id_atributo    grl_atributo.id_componente%TYPE     := p_id_atributo;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_p_id_atributo', v_p_id_atributo, 'required|int')
        ));

        DELETE FROM grl_atributo 
        WHERE id_atributo = v_p_id_atributo;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_p_id_atributo id, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", 0 id, 'Error al momento de eliminar un atributo, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_p_id_atributo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Delete_Atributo;


    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_Atributo (
        p_id_atributo   IN grl_atributo.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT a.id_atributo AS "idAtributo", a.id_componente AS "idComponente", c.nombre AS "componente", a.nombre AS "atributo", a.id_tipo_dato AS "idTipoDato", td.nombre AS "tipoDato", a.largo AS "largo", 
                   a.posicion AS "posicion", a.id_estado AS "idEstado", es.nombre AS "estado", a.objeto AS "objeto", a.columna_id AS "columnaId", a.columna_data AS "columnaData", 
                   a.obligatorio AS "obligatorio", a.valor_default AS "valorDefault", a.mascara as "mascara"
            FROM grl_atributo a INNER JOIN grl_componente c ON c.id_componente = a.id_componente
                                INNER JOIN grl_referencia_item td ON td.id_item = a.id_tipo_dato
                                INNER JOIN grl_referencia_item es ON es.id_item = a.id_estado
            WHERE a.id_atributo = p_id_atributo;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_atributo'    VALUE p_id_atributo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetById_Atributo;

    ----------------------------------------
    -- SELECT todos los atributos de un nivel vigentes
    ----------------------------------------
    PROCEDURE GetByComponente_Atributo (
        p_id_componente      IN grl_atributo.id_componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT a.id_atributo AS "idAtributo", a.id_componente AS "idComponente", c.nombre AS "componente", a.nombre AS "atributo", a.id_tipo_dato AS "idTipoDato", td.nombre AS "tipoDato", a.largo AS "largo", 
                   a.posicion AS "posicion", a.id_estado AS "idEstado", es.nombre AS "estado", a.objeto AS "objeto", a.columna_id AS "columnaId", a.columna_data AS "columnaData", 
                   a.obligatorio AS "obligatorio", a.valor_default AS "valorDefault", a.mascara as "mascara"
            FROM grl_atributo a INNER JOIN grl_componente c ON c.id_componente = a.id_componente
                                INNER JOIN grl_referencia_item td ON td.id_item = a.id_tipo_dato
                                INNER JOIN grl_referencia_item es ON es.id_item = a.id_estado
            WHERE  a.id_estado = const_Atributo_VIGENTE
            AND    a.id_componente = p_id_componente
            ORDER BY a.nombre;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_componente'    VALUE p_id_componente,
                    'fecha'         VALUE sysdate,
                    'ora-error'     VALUE v_errorcode,
                    'ora-msg'       VALUE v_errormessage,
                    'linea_err'     VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetByComponente_Atributo;


    ----------------------------------------
    -- SELECT todos los atributos 
    ----------------------------------------
    PROCEDURE GetAll_Atributo (
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT a.id_atributo AS "idAtributo", a.id_componente AS "idComponente", c.nombre AS "componente", a.nombre AS "atributo", a.id_tipo_dato AS "idTipoDato", td.nombre AS "tipoDato", a.largo AS "largo", 
                   a.posicion AS "posicion", a.id_estado AS "idEstado", es.nombre AS "estado", a.objeto AS "objeto", a.columna_id AS "columnaId", a.columna_data AS "columnaData", 
                   a.obligatorio AS "obligatorio", a.valor_default AS "valorDefault", a.mascara as "mascara"
            FROM grl_atributo a INNER JOIN grl_componente c ON c.id_componente = a.id_componente
                                INNER JOIN grl_referencia_item td ON td.id_item = a.id_tipo_dato
                                INNER JOIN grl_referencia_item es ON es.id_item = a.id_estado
            ORDER BY a.nombre;


    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'fecha'         VALUE sysdate,
                    'ora-error'     VALUE v_errorcode,
                    'ora-msg'       VALUE v_errormessage,
                    'linea_err'     VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetAll_Atributo;

END pkg_grl_atributo;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_COMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_COMPONENTE" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_Componente
-- PURPOSE:    Package para las funciones CRUD de los componentes de una estruturas
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_Componente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app        NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_Componente (
        p_nombre            IN grl_Componente.nombre%TYPE,
        p_descripcion       IN grl_Componente.descripcion%TYPE,
        p_id_estructura     IN grl_Componente.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_id               grl_Componente.id_Componente%TYPE       := 0;
    v_nombre           grl_Componente.nombre%TYPE         := upper(trim(p_nombre)); 
    v_descripcion      grl_Componente.descripcion%TYPE    := trim(p_descripcion);
    v_id_estructura    grl_Componente.id_estructura%TYPE  := nvl(p_id_estructura,0);
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('descripcion', v_descripcion, 'required|string'),
                VALIDATOR.RULE('id_estructura', v_id_estructura, 'required|int')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(v_nombre,1,60);
        end if;
        if (pkg_validaciones.tamanio_campo(v_descripcion,2000)) THEN
            v_descripcion := substr(v_descripcion,1,2000);
        end if;

        --- Se valida que el nombre la estructura no este repetido
        BEGIN
            SELECT count(1) INTO v_rows 
            FROM grl_Componente
            WHERE nombre = v_nombre AND id_estructura = p_id_estructura;

            if (v_rows > 0) then
                OPEN p_cursor FOR
                     SELECT 'ERROR' AS "status", 0 id, 'El nombre del nivel ya esta definido en la estructura.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
                return;
            end if;
        END;

        SELECT grl_Componentes_seq.NEXTVAL INTO v_id FROM dual;

        INSERT INTO grl_Componente (id_Componente, id_estructura, nombre, descripcion)
        VALUES (v_id, v_id_estructura, v_nombre, v_descripcion);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           OPEN p_cursor FOR
                SELECT v_id id, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", 0 id, 'Error al momento de registrar el nivel, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
           return;
        END IF;

        --- Se valida si es el primer componente de la estructura para propagar el punto de inicio.
        BEGIN
            SELECT count(1) INTO v_rows
            FROM grl_componente
            WHERE id_estructura = v_id_estructura;
            IF (v_rows = 1) THEN
                INSERT INTO grl_elemento (id_item, nombre, id_componente, id_padre)
                VALUES (v_id, v_nombre, v_id, null);

                UPDATE grl_estructura 
                SET punto_inicio = v_id
                WHERE id_estructura = v_id_estructura;
                COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                 OPEN p_cursor FOR
                      SELECT v_id id, 'Componente ra�z creado y se presenta error en la propagaci�n del punto de inicio. Contacte al administrador.' AS message FROM dual;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_id,
                    'v_nombre'         VALUE v_nombre,
                    'v_descripcion'    VALUE v_descripcion,
                    'v_id_estructura'  VALUE v_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Insert_Componente;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE Update_Componente (
        p_id_Componente     IN grl_Componente.id_Componente%TYPE,
        p_id_estructura     IN grl_Componente.id_estructura%TYPE,
        p_nombre            IN grl_Componente.nombre%TYPE,
        p_descripcion       IN grl_Componente.descripcion%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_id_Componente    grl_Componente.id_Componente%TYPE  := nvl(p_id_Componente,0);
    v_id_estructura    grl_Componente.id_estructura%TYPE  := nvl(p_id_estructura,0);
    v_nombre           grl_Componente.nombre%TYPE         := upper(trim(p_nombre)); 
    v_descripcion      grl_Componente.descripcion%TYPE    := trim(p_descripcion);
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('descripcion', v_descripcion, 'required|string'),
                VALIDATOR.RULE('id_Componente', v_id_Componente, 'required|int'),
                VALIDATOR.RULE('id_estructura', v_id_estructura, 'required|int')
        ));

        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(v_nombre,1,60);
        end if;
        if (pkg_validaciones.tamanio_campo(v_descripcion,2000)) THEN
            v_descripcion := substr(v_descripcion,1,2000);
        end if;

        --- Se valida que el nombre la estructura no este repetido
        BEGIN
            SELECT count(1) INTO v_rows 
            FROM grl_Componente
            WHERE nombre = v_nombre AND id_Componente != p_id_Componente AND id_estructura = v_id_estructura;

            if (v_rows > 0) then
                OPEN p_cursor FOR
                     SELECT 'ERROR' AS "status", 0 id, 'El nombre del nivel ya esta definido en la estructura.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
                return;
            end if;
        END;

        UPDATE grl_Componente
        SET nombre          = p_nombre,
            descripcion     = p_descripcion
        WHERE id_Componente = v_id_Componente;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_estructura id, CONST.MSG_UPDATE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", v_id_estructura id, 'Error al momento de actualizar el nivel, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_Componente'       VALUE v_id_Componente,
                    'v_nombre'         VALUE v_nombre,
                    'v_descripcion'    VALUE v_descripcion,
                    'v_id_estructura'  VALUE v_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Update_Componente;

    ----------------------------------------
    -- DELETE
    ----------------------------------------
    PROCEDURE Delete_Componente (
        p_id_Componente          IN grl_Componente.id_Componente%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS
    v_id_Componente         grl_Componente.id_Componente%TYPE       := nvl(p_id_Componente,0);
    v_rows             NUMBER;
    BEGIN
        SELECT count(1) INTO v_rows 
        FROM grl_elemento
        WHERE id_componente = p_id_Componente;
        IF (v_rows > 0) THEN
             OPEN p_cursor FOR
                     SELECT 'ERROR' AS "status", 0 id, 'No se puede eliminar, tiene elementos asignados.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, 'No se puede eliminar, tiene elementos asignados.');
                return;
        END IF;

        --- Se eliminan las relaciones del subnivel
        DELETE FROM grl_subcomponente s
        WHERE id_Componente = v_id_Componente;

        DELETE FROM grl_atributo
        WHERE id_componente = v_id_componente;

        DELETE FROM grl_Componente
        WHERE id_Componente = v_id_Componente;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_Componente id, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 'ERROR' AS "status", v_id_Componente id, 'Error al momento de eliminar el nivel, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001,'Elemento Ra�z no puede ser eliminado.');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_Componente'       VALUE v_id_Componente,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Delete_Componente;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_Componente (
        p_id_Componente      IN grl_Componente.id_Componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_Componente AS "idComponente", id_estructura AS "idEstructura", nombre AS "nombre", descripcion AS "descripcion"
             FROM grl_Componente
            WHERE id_Componente = p_id_Componente;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_Componente'  VALUE p_id_Componente,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' AS "status", v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetById_Componente;

    ----------------------------------------
    -- SELECT todos
    ----------------------------------------
    PROCEDURE GetAll_Componente (
        v_id_estructura    IN grl_Componente.id_estructura%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    ) IS

    BEGIN
        OPEN p_cursor FOR
            SELECT id_Componente AS "idComponente", id_estructura AS "idEstructura", nombre AS "nombre", descripcion AS "descripcion"
             FROM grl_Componente
            WHERE id_estructura = v_id_estructura
            ORDER BY nombre;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_estructura'  VALUE v_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetAll_Componente;

END pkg_grl_Componente;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_DATO_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_DATO_ELEMENTO" IS
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
    v_id_app        NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_Datos (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_id_item           grl_dato_elemento.id_item%TYPE       := p_id_item;
    v_id_atributo       grl_dato_elemento.id_atributo%TYPE   := p_id_atributo;
    v_valor             grl_dato_elemento.valor%TYPE         := upper(trim(p_valor)); 
    v_id_usuario        grl_dato_elemento.id_usuario%TYPE    := p_id_usuario;
    v_rows              NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_item', v_id_item, 'required|int'),
                VALIDATOR.RULE('v_id_atributo', v_id_atributo, 'required|int'),
                VALIDATOR.RULE('v_valor', v_valor, 'string'),
                VALIDATOR.RULE('v_id_usuario', v_id_usuario, 'required|int')
        ));

        if (pkg_validaciones.tamanio_campo(v_valor,2000)) THEN
            v_valor := substr(v_valor,1,2000);
        end if;
        

        INSERT INTO grl_dato_elemento (id_item, id_atributo, valor, ult_fec_act, id_usuario)
        VALUES (v_id_item, v_id_atributo, v_valor, sysdate, v_id_usuario);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_item id, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de registrar el valor de un elemento, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE v_id_item,
                    'v_id_atributo'    VALUE v_id_atributo,
                    'v_valor'          VALUE v_valor,
                    'v_id_usuario'     VALUE v_id_usuario,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Insert_Datos;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE Update_Dato (
        p_id_item           IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo       IN grl_dato_elemento.id_atributo%TYPE,
        p_valor             IN grl_dato_elemento.valor%TYPE,
        p_id_usuario        IN grl_dato_elemento.id_usuario%TYPE,
        p_cursor            OUT SYS_REFCURSOR 
    ) IS

    v_id_item           grl_dato_elemento.id_item%TYPE       := p_id_item;
    v_id_atributo       grl_dato_elemento.id_atributo%TYPE   := p_id_atributo;
    v_valor             grl_dato_elemento.valor%TYPE         := upper(trim(p_valor)); 
    v_id_usuario        grl_dato_elemento.id_usuario%TYPE    := p_id_usuario;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_item', v_id_item, 'required|int'),
                VALIDATOR.RULE('v_id_atributo', v_id_atributo, 'required|int'),
                VALIDATOR.RULE('v_valor', v_valor, 'string'),
                VALIDATOR.RULE('v_id_usuario', v_id_usuario, 'required|int')
        ));

        if (pkg_validaciones.tamanio_campo(v_valor,2000)) THEN
            v_valor := substr(v_valor,1,2000);
        end if;

        UPDATE grl_dato_elemento
        SET valor        = p_valor,
            ult_fec_act  = sysdate,
            id_usuario   = p_id_usuario
        WHERE id_atributo = v_id_atributo AND id_item = v_id_item;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_item id, CONST.MSG_UPDATE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de actualizar el valor de un elemento, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE v_id_item,
                    'v_id_atributo'    VALUE v_id_atributo,
                    'v_valor'          VALUE v_valor,
                    'v_id_usuario'     VALUE v_id_usuario,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Update_Dato;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_Dato (
        p_id_item       IN grl_dato_elemento.id_item%TYPE,
        p_id_atributo   IN grl_dato_elemento.id_atributo%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT de.id_item AS "idItem", de.id_atributo AS "idAtributo", de.valor AS "valor", de.ult_fec_act AS "fechaUltimaActualizacion", de.id_usuario AS "idUsuario",
                   a.nombre AS "atributo", a.id_tipo_dato AS "idTipoDato", r.nombre AS "tipoDato", a.largo AS "largo", a.objeto AS "objeto", a.columna_id AS "columnasId", a.columna_data AS "columnaData", a.obligatorio AS "obligatorio", a.valor_default AS "valorDefault"
             FROM grl_referencia_item r, grl_atributo a, grl_dato_elemento de
            WHERE r.id_item = a.id_tipo_dato AND a.id_atributo = de.id_atributo 
            AND de.id_atributo = p_id_atributo AND de.id_item = p_id_item;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE p_id_item,
                    'v_id_atributo'    VALUE p_id_atributo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END GetById_Dato;

    ----------------------------------------
    -- SELECT todos (hijos)
    ----------------------------------------
    PROCEDURE GetAll_Dato (
        p_id_item          IN grl_dato_elemento.id_item%TYPE,
        p_cursor           OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT de.id_item AS "idItem", de.id_atributo AS "idAtributo", de.valor AS "valor", de.ult_fec_act AS "fechaUltimaActualizacion", de.id_usuario AS "idUsuario",
                   a.nombre AS "atributo", a.id_tipo_dato AS "idTipoDato", r.nombre AS "tipoDato", a.largo AS "largo", a.objeto AS "objeto", a.columna_id AS "columnasId", a.columna_data AS "columnaData", a.obligatorio AS "obligatorio", a.valor_default AS "valorDefault"
             FROM grl_referencia_item r, grl_atributo a, grl_dato_elemento de
            WHERE r.id_item = a.id_tipo_dato AND a.id_atributo = de.id_atributo AND de.id_item = p_id_Item;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE p_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END GetAll_Dato;

END pkg_grl_dato_elemento;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ELEMENTO" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento
-- PURPOSE:    Package para las funciones CRUD de datos que conforman una estruturas
--  
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        14/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_elemento
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app       NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_Elemento (
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS
    
    v_id               grl_elemento.id_componente%TYPE  := 0;
    v_nombre           grl_elemento.nombre%TYPE         := upper(trim(p_nombre)); 
    v_id_componente    grl_elemento.id_componente%TYPE  := nvl(p_id_componente,0);
    v_id_padre         grl_elemento.id_padre%TYPE       := p_id_padre;
    v_rows             NUMBER;
    v_id_componente_padre  NUMBER;
    BEGIN
        --- Validaciones de los parametros
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('v_id_componente', v_id_componente, 'required|int')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(v_nombre,1,60);
        end if;

        ---- Se valida si es valido el ID_PADRE
        BEGIN
            SELECT id_componente INTO v_id_componente_padre
              FROM grl_elemento
              WHERE id_item = v_id_padre;

            SELECT count(1) into v_rows
              FROM grl_subcomponente
              WHERE id_padre = v_id_componente_padre AND id_componente = v_id_componente;

            IF (v_rows <= 0) THEN
                OPEN p_cursor FOR
                    SELECT 0 id, 'Inserci�n de elemento no v�lida.' AS message FROM dual;
                return;
            END IF;
        END;

        SELECT grl_estructuras_seq.NEXTVAL INTO v_id FROM dual;

        INSERT INTO grl_elemento (id_item, nombre, id_componente, id_padre)
        VALUES (v_id, v_nombre, v_id_componente, v_id_padre);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id id, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de registrar un elemento, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_id,
                    'v_nombre'         VALUE v_nombre,
                    'v_id_componente'       VALUE v_id_componente,
                    'id_padre'         VALUE v_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Insert_Elemento;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE Update_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_nombre            IN grl_elemento.nombre%TYPE,
        p_id_componente     IN grl_elemento.id_componente%TYPE,
        p_id_padre          IN grl_elemento.id_padre%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_id_item          grl_elemento.id_componente%TYPE  := nvl(p_id_item,0);
    v_nombre           grl_elemento.nombre%TYPE         := upper(trim(p_nombre)); 
    v_id_componente    grl_elemento.id_componente%TYPE  := nvl(p_id_componente,0);
    v_id_padre         grl_elemento.id_padre%TYPE       := p_id_padre;
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('nombre', v_nombre, 'required|string'),
                VALIDATOR.RULE('v_id_componente', v_id_componente, 'required|int'),
                VALIDATOR.RULE('v_id_componente', v_id_item, 'required|int')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(v_nombre,1,60);
        end if;

        UPDATE grl_elemento
        SET nombre       = p_nombre,
            id_componente     = p_id_componente,
            id_padre     = p_id_padre
        WHERE id_item = v_id_item;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_item id, v_nombre nombre, v_id_componente id_componente, v_id_padre id_padre, CONST.MSG_UPDATE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de actualizar un elemento, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE v_id_item,
                    'v_nombre'         VALUE v_nombre,
                    'v_id_componente'       VALUE v_id_componente,
                    'id_padre'         VALUE v_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Update_Elemento;

    ----------------------------------------
    -- DELETE
    ----------------------------------------
    PROCEDURE Delete_Elemento (
        p_id_item           IN grl_elemento.id_item%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS
    v_id_item          grl_componente.id_componente%TYPE       := nvl(p_id_item,0);
    v_rows             NUMBER;
    BEGIN
        --- Se eliminan las relaciones de la estructura
        DELETE FROM grl_dato_elemento
        WHERE id_item = v_id_item;

        DELETE FROM grl_elemento
        WHERE id_item = v_id_item;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT p_id_item id, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT p_id_item id, 'Error al momento de eliminar el elemento, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE v_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END Delete_Elemento;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_Elemento (
        p_id_item       IN grl_elemento.id_item%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_item AS "idItem", nombre AS "nombre", id_componente AS "idComponente", id_padre AS "idPadre"
             FROM grl_elemento
            WHERE id_item = p_id_item;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_item'        VALUE p_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
    END GetById_Elemento;


END pkg_grl_elemento;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ELEMENTO_PADRE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ELEMENTO_PADRE" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_elemento_padre
-- PURPOSE:    Package para las funciones CRUD de la relacion de un elemento con uno o m�s padres.
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        4/07/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_elemento_padre
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app        NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    ) IS

    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_componente', p_id_item, 'required|int'),
                VALIDATOR.RULE('v_id_padre', p_id_padre, 'required|int')
        ));

        --- Se valida que el padre no exista.
        SELECT count(1) INTO v_rows 
        FROM grl_elemento_padre
        WHERE id_item = p_id_item AND id_padre = p_id_padre;

        IF (v_rows > 0) THEN
            OPEN p_cursor FOR
                SELECT 0 id, 'Relaci�n ya se encuentra registrada.' AS message FROM dual;

            RETURN;
        END IF;

        INSERT INTO grl_elemento_padre (id_item, id_padre)
        values (p_id_item, p_id_padre);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT p_id_item id_componente, p_id_padre id_padre, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de registrar el padre, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_item'        VALUE p_id_item,
                    'p_id_padre'       VALUE p_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Insert_elemento_padre;


    ----------------------------------------
    -- DELETE
    ----------------------------------------
    PROCEDURE Delete_elemento_padre (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_id_padre            IN grl_elemento_padre.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    ) IS

    v_rows             NUMBER;
    BEGIN
        --- Se elimina la relaci�n
        DELETE FROM grl_elemento_padre 
        WHERE id_item = p_id_item AND id_padre = p_id_padre;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT p_id_item id_componente, p_id_padre id_padre, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT p_id_item id, 'Error al momento de eliminar el padre, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_componente'  VALUE p_id_item,
                    'v_id_padre'       VALUE p_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Delete_elemento_padre;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE Get_padres (
        p_id_item             IN grl_elemento_padre.id_item%TYPE,
        p_cursor             OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_item AS "idItem", id_padre AS "idPadre"
             FROM grl_elemento_padre
            WHERE id_item = p_id_item;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_item'  VALUE p_id_item,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Get_padres;


    PROCEDURE Get_hijos (
        p_id_padre      IN grl_elemento_padre.id_padre%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_item AS "idItem", id_padre AS "idPadre"
             FROM grl_elemento_padre
            WHERE id_padre = p_id_padre;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_padre'       VALUE p_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Get_hijos;

END pkg_grl_elemento_padre;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_ESTRUCTURA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_ESTRUCTURA" IS
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
    v_id_app        NUMBER := 7;     -- ID del package
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_Estructura (
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR  
    ) IS

    v_id               grl_estructura.id_estructura%TYPE  := 0;
    v_nombre           grl_estructura.nombre%TYPE := upper(trim(p_nombre));
    v_descripcion      grl_estructura.descripcion%TYPE := trim(p_descripcion);
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('nombre', p_nombre, 'required|string|max=60'),
                VALIDATOR.RULE('descripcion', p_descripcion, 'required|string|max=2000'),
                VALIDATOR.RULE('id_estado', p_id_estado, 'required|int'),
                VALIDATOR.RULE('id_tipo', p_id_tipo, 'required|int')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(p_nombre,1,60);
        end if;
        if (pkg_validaciones.tamanio_campo(v_descripcion,2000)) THEN
            v_descripcion := substr(p_descripcion,1,2000);
        end if;

        --- Se valida que el nombre la estructura no este repetido
        BEGIN
            SELECT count(1) INTO v_rows 
            FROM grl_estructura
            WHERE nombre = v_nombre;

            if (v_rows > 0) then
                OPEN p_cursor FOR
                     SELECT 'ERROR' status, 0 id, 'El nombre de la estructura ya esta definido.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
                return;
            end if;
        END;

        SELECT grl_estructuras_seq.NEXTVAL INTO v_id FROM dual;

        INSERT INTO grl_estructura (id_estructura, nombre, descripcion, id_estado, id_tipo)
        VALUES (v_id, v_nombre, v_descripcion, p_id_estado, p_id_tipo);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id id, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           OPEN p_cursor FOR
                SELECT 'ERROR' status, 0 id, 'Error al momento de registrar la estructura, si persiste contacte al administrador.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id'             VALUE v_id,
                    'p_nombre'         VALUE p_nombre,
                    'p_descripcion'    VALUE p_descripcion,
                    'p_id_estado'      VALUE p_id_estado,
                    'p_id_tipo'        VALUE p_id_tipo,
                    'fecha'            VALUE sysdate,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);

    END Insert_Estructura;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE Update_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_nombre            IN grl_estructura.nombre%TYPE,
        p_descripcion       IN grl_estructura.descripcion%TYPE,
        p_id_estado         IN grl_estructura.id_estado%TYPE,
        p_id_tipo           IN grl_estructura.id_tipo%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS

    v_nombre           grl_estructura.nombre%TYPE         := upper(trim(p_nombre)); 
    v_descripcion      grl_estructura.descripcion%TYPE    := trim(p_descripcion);
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('id_estructura', p_id_estructura, 'required|int'),
                VALIDATOR.RULE('nombre', v_nombre, 'required|string|max=60'),
                VALIDATOR.RULE('descripcion', v_descripcion, 'required|string|max=2000'),
                VALIDATOR.RULE('id_estado', p_id_estado, 'required|int'),
                VALIDATOR.RULE('id_tipo', p_id_tipo, 'required|int')
        ));

        --- Ajusta tama�o del campo.
        if (pkg_validaciones.tamanio_campo(v_nombre,60)) THEN
            v_nombre := substr(v_nombre,1,60);
        end if;
        if (pkg_validaciones.tamanio_campo(v_descripcion,2000)) THEN
            v_descripcion := substr(v_descripcion,1,2000);
        end if;

        --- Se valida que el nombre la estructura no este repetido
        BEGIN
            SELECT count(1) INTO v_rows 
            FROM grl_estructura
            WHERE nombre = v_nombre AND id_estructura != p_id_estructura;

            if (v_rows > 0) then
                OPEN p_cursor FOR
                     SELECT 'ERROR' status, p_id_estructura id, 'El nombre de la estructura ya esta definido.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
                return;
            end if;
        END;

        UPDATE grl_estructura
        SET nombre          = p_nombre,
            descripcion     = p_descripcion,
            id_estado       = p_id_estado,
            id_tipo         = p_id_tipo
        WHERE id_estructura = p_id_estructura;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT p_id_estructura id, CONST.MSG_UPDATE_OK AS message FROM dual;
        ELSE
           OPEN p_cursor FOR
                SELECT 'ERROR' status, p_id_estructura id, 'Error al momento de actualizar la estructura, si persiste contacte al administrador.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_estructura'  VALUE p_id_estructura,
                    'v_nombre'         VALUE v_nombre,
                    'v_descripcion'    VALUE v_descripcion,
                    'v_id_estado'      VALUE p_id_estado,
                    'p_id_tipo'        VALUE p_id_tipo,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Update_Estructura;

    ----------------------------------------
    -- DELETE
    ----------------------------------------
    PROCEDURE Delete_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS
    v_id_estructura    grl_estructura.id_estructura%TYPE  := nvl(p_id_estructura,0);
    v_rows             NUMBER;
    BEGIN
        --- Valida si se puede eliminar la estructura, no tiene elementos asociados.
        SELECT count(1) INTO v_rows
        FROM grl_elemento
        START WITH id_item = (select punto_inicio from grl_estructura where id_estructura = v_id_estructura) 
        CONNECT BY PRIOR id_item = id_padre;

        IF  (v_rows > 1) THEN
            OPEN p_cursor FOR
                 SELECT 'ERROR' status, v_id_estructura id, 'No se puede eliminar la estructura ya que tiene elementos registrados.' AS message FROM dual;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            return;
        END IF;

        --- Se eliminan las relaciones de la estructura
        DELETE FROM grl_elemento 
        WHERE id_item = (select punto_inicio from grl_estructura where id_estructura = v_id_estructura);

        DELETE FROM grl_subcomponente s
        WHERE EXISTS (SELECT 'x' FROM grl_componente WHERE id_componente = s.id_componente AND id_estructura = v_id_estructura);

        DELETE FROM grl_componente
        WHERE id_estructura = v_id_estructura;

        DELETE FROM grl_estructura
        WHERE id_estructura = v_id_estructura;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_estructura id, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           rollback;
           OPEN p_cursor FOR
                SELECT 'ERROR' status, v_id_estructura id, 'Error al momento de eliminar la estructura, si persiste contacte al administrador.' AS message FROM dual;
           RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_estructura'  VALUE v_id_estructura,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Delete_Estructura;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_Estructura (
        p_id_estructura     IN grl_estructura.id_estructura%TYPE,
        p_cursor            OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT e.id_estructura AS "idEstructura", e.nombre AS "nombre", e.descripcion AS "descripcion", e.id_estado AS "idEstado", e.id_tipo AS "idTipo",
                   d.nombre AS "estado", t.nombre AS "tipo"
             FROM grl_referencia_item t, grl_referencia_item d, grl_estructura e
            WHERE t.id_item = e.id_tipo
            AND d.id_item = e.id_estado
            AND e.id_estructura = p_id_estructura;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'p_id_estructura'   VALUE p_id_estructura,
                    'ora-error'         VALUE v_errorcode,
                    'ora-msg'           VALUE v_errormessage
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetById_Estructura;

    ----------------------------------------
    -- SELECT todos
    ----------------------------------------
    PROCEDURE GetAll_Estructuras (
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT e.id_estructura AS "idEstructura", e.nombre AS "nombre", e.descripcion AS "descripcion", e.id_estado AS "idEstado", e.id_tipo AS "idTipo",
                   d.nombre AS "estado", t.nombre AS "tipo"
             FROM grl_referencia_item t, grl_referencia_item d, grl_estructura e
            WHERE t.id_item = e.id_tipo
            AND d.id_item = e.id_estado
            ORDER BY e.nombre;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'fecha'             VALUE sysdate,
                    'ora-error'         VALUE v_errorcode,
                    'ora-msg'           VALUE v_errormessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception            
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT 'ERROR' status, v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetAll_Estructuras;

END pkg_grl_estructura;

/
--------------------------------------------------------
--  DDL for Package Body PKG_GRL_SUBCOMPONENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_GRL_SUBCOMPONENTE" IS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_grl_subcomponente
-- PURPOSE:    Package para las funciones CRUD de la relacion de dependencia entre los componentes en una estructura
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        13/01/2026  Juan Herqui�igo   1. Package para la manipulacion de los registros de la tabla grl_subcomponente
-- 2.0
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    v_id_app        NUMBER := 7;     -- ID del package
    v_data          CLOB;            -- Variable para almacenar un JSON
    v_errorcode     VARCHAR2(2000);  -- Variable para el codigo de error 
    v_errormessage  VARCHAR2(2000);  -- Variable para el mensaje de error
    v_logId         NUMBER;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE Insert_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    ) IS

    v_id_componente       grl_subcomponente.id_componente%TYPE  := nvl(p_id_componente,0); 
    v_id_padre            grl_subcomponente.id_padre%TYPE       := nvl(p_id_padre,0);
    v_rows             NUMBER;
    BEGIN
        --- Validaciones de los parametros.
        VALIDATOR.VALIDATE(T_RULES(
                VALIDATOR.RULE('v_id_componente', v_id_componente, 'required|int'),
                VALIDATOR.RULE('v_id_padre', v_id_padre, 'required|int')
        ));

        --- Se valida que el nombre la estructura no este repetido
        SELECT count(1) INTO v_rows 
        FROM grl_subcomponente
        WHERE id_componente = v_id_componente AND id_padre = v_id_padre;

        IF (v_rows > 0) THEN
            OPEN p_cursor FOR
                SELECT 0 id, 'Relaci�n ys se encuentra registrada.' AS message FROM dual;

            return;
        END IF;

        INSERT INTO grl_subcomponente (id_componente, id_padre)
        values (v_id_componente, v_id_padre);

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_componente id_componente, v_id_padre id_padre, CONST.MSG_INSERT_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT 0 id, 'Error al momento de registrar el subnivel, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_componente'  VALUE v_id_componente,
                    'v_id_padre'       VALUE v_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Insert_subcomponente;


    ----------------------------------------
    -- DELETE
    ----------------------------------------
    PROCEDURE Delete_subcomponente (
        p_id_componente       IN grl_subcomponente.id_componente%TYPE,
        p_id_padre            IN grl_subcomponente.id_padre%TYPE,
        p_cursor              OUT SYS_REFCURSOR
    ) IS

    v_id_componente    grl_subcomponente.id_componente%TYPE   := nvl(p_id_componente,0); 
    v_id_padre         grl_subcomponente.id_padre%TYPE        := nvl(p_id_padre,0);
    v_rows             NUMBER;
    BEGIN
        SELECT count(1) INTO v_rows 
        FROM grl_subcomponente
        WHERE id_componente = v_id_componente;
        IF (v_rows <= 1) THEN
             OPEN p_cursor FOR
                     SELECT 'ERROR' AS "status", 0 id, 'No se puede eliminar el �nico componente padre.' AS message FROM dual;
                RAISE_APPLICATION_ERROR(-20001, CONST.MSG_ERROR_INESPERADO);
                return;
        END IF;
        --- Se eliminan las relaciones de la estructura
        DELETE FROM grl_subcomponente s
        WHERE id_componente = v_id_componente AND id_padre = v_id_padre;

        v_rows := SQL%ROWCOUNT;

        IF v_rows > 0 THEN
           COMMIT;
           OPEN p_cursor FOR
                SELECT v_id_componente id_componente, v_id_padre id_padre, CONST.MSG_DELETE_OK AS message FROM dual;
        ELSE
           ROLLBACK;
           OPEN p_cursor FOR
                SELECT v_id_componente id, 'Error al momento de eliminar el subnivel, si persiste contacte al administrador.' AS message FROM dual;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_componente'  VALUE v_id_componente,
                    'v_id_padre'       VALUE v_id_padre,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END Delete_subcomponente;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GetById_subcomponente (
        p_id_componente      IN grl_subcomponente.id_componente%TYPE,
        p_cursor        OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_componente AS "idComponente", id_padre AS "idPadre"
             FROM grl_subcomponente
            WHERE id_componente = p_id_componente;

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            --- Se pasan los parametros a JSON
            SELECT JSON_OBJECT(
                    'v_id_componente'  VALUE p_id_componente,
                    'fecha'            VALUE sysdate,
                    'ora-error'        VALUE v_errorcode,
                    'ora-msg'          VALUE v_errormessage,
                    'linea_err'        VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            --- Se registra la exception          
            PKG_LOG.REGISTRA_LOG(v_id_app, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "id", CONST.MSG_ERROR_INESPERADO AS "message" FROM DUAL;
            ---UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage);
    END GetById_subcomponente;


END pkg_grl_subcomponente;

/
--------------------------------------------------------
--  DDL for Package Body PKG_LOG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_LOG" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_log 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        02/10/2025   jmaizares         1. Package para la manipulacion de los registros de la tabla log_system 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
v_id_referencia number := 37;-- se utiliza para poder ir a la tabla [grl_referencia_item] las definiciones del tipo de registro que se esta realizando

PROCEDURE REGISTRA_LOG( 
                        p_app_id   in auditor.log_system.app_id%type default null, 
                        p_tipo     in auditor.log_system.tipo%type default null, 
                        p_log_json in auditor.log_system.log_json%type,
                        p_titulo   in auditor.log_system.titulo%type default null, 
                        p_origen   in auditor.log_system.origen%type default null                                
                      ) is 

v_app_id            auditor.log_system.app_id%type         := trim(p_app_id); 
v_tipo              auditor.log_system.tipo%type           := trim(p_tipo); 
v_titulo            auditor.log_system.titulo%type         := trim(p_titulo); 
v_origen            auditor.log_system.origen%type         := trim(p_origen); 
v_log_json          auditor.log_system.log_json%type       := trim(p_log_json); 
v_log_id            auditor.log_system.log_id%type         := genera_log_id();

v_nombre_llamado    varchar2(200)                          := null;
v_esquema_origen   varchar2(100);
v_linea_llamado     pls_integer;

PRAGMA AUTONOMOUS_TRANSACTION;

Begin


    if v_log_json is null or length(v_log_json) = 0 then --el campo [log_json] no puede ser nulo
        raise_application_error(-20012, 'El campo [p_log_json] esta vacio');         
    end if; 


    if v_origen is null then

        -- Validamos que exista un nivel 2 (por si se ejecutó desde un bloque anónimo)
        -- Si se llama directamente, devuelve null
        if utl_call_stack.dynamic_depth >= 2 then

            v_esquema_origen := utl_call_stack.owner(2); -- obtener el esquema

            -- obtener el nombre completo (Paquete.Procedimiento)
            -- SUBPROGRAMA devuelve una colección, se usa el .LAST para el nombre final
            declare
                subprog utl_call_stack.unit_qualified_name;
            begin
                subprog := utl_call_stack.subprogram(2);
                for i in 1..subprog.count loop
                    v_nombre_llamado := v_nombre_llamado || 
                                        case when i > 1 then '.' end || 
                                        subprog(i);
                end loop;
            end;

            v_linea_llamado := utl_call_stack.unit_line(2); --obtener nro de linea
            v_origen        := v_esquema_origen || '.' || v_nombre_llamado||' l�nea: ' || v_linea_llamado;

        end if;

    end if;

    insert_registro(v_log_id,v_app_id,v_log_json,v_tipo,v_titulo,v_origen);

exception when others then    
    rollback; 
    --notificar via correo el problema
    dbms_output.put_line('error=>'||sqlerrm);
end; 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

PROCEDURE REGISTRA_LOG( 
                        p_app_id   in auditor.log_system.app_id%type default null, 
                        p_tipo     in auditor.log_system.tipo%type default null, 
                        p_log_json in auditor.log_system.log_json%type,
                        p_log_id   out number               
                      ) is 

v_app_id            auditor.log_system.app_id%type         := trim(p_app_id); 
v_tipo              auditor.log_system.tipo%type           := trim(p_tipo); 
v_origen            auditor.log_system.origen%type; 
v_log_json          auditor.log_system.log_json%type       := trim(p_log_json); 
v_log_id            auditor.log_system.log_id%type         := genera_log_id();

v_nombre_llamado    varchar2(200)                          := null;
v_esquema_origen    varchar2(100);
v_linea_llamado     pls_integer;

PRAGMA AUTONOMOUS_TRANSACTION;

Begin


    if v_log_json is null or length(v_log_json) = 0 then --el campo [log_json] no puede ser nulo
        raise_application_error(-20012, 'El campo [p_log_json] esta vacio');         
    end if; 


    if v_origen is null then

        -- Validamos que exista un nivel 2 (por si se ejecutó desde un bloque anónimo)
        -- Si se llama directamente, devuelve null
        if utl_call_stack.dynamic_depth >= 2 then

            v_esquema_origen := utl_call_stack.owner(2); -- obtener el esquema

            -- obtener el nombre completo (Paquete.Procedimiento)
            -- SUBPROGRAMA devuelve una colección, se usa el .LAST para el nombre final
            declare
                subprog utl_call_stack.unit_qualified_name;
            begin
                subprog := utl_call_stack.subprogram(2);
                for i in 1..subprog.count loop
                    v_nombre_llamado := v_nombre_llamado || 
                                        case when i > 1 then '.' end || 
                                        subprog(i);
                end loop;
            end;

            v_linea_llamado := utl_call_stack.unit_line(2); --obtener nro de linea
            v_origen        := v_esquema_origen || '.' || v_nombre_llamado||' l�nea: ' || v_linea_llamado;

        end if;

    end if;


    insert_registro(v_log_id,v_app_id,v_log_json,v_tipo,null,v_origen);

    p_log_id := v_log_id;

exception when others then    
    rollback;
    p_log_id := null; 
    --notificar via correo el problema
    dbms_output.put_line('error=>'||sqlerrm);
end; 

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
PROCEDURE INSERT_REGISTRO(p_log_id   in auditor.log_system.log_id%type,
                          p_app_id   in auditor.log_system.app_id%type,                            
                          p_log_json in auditor.log_system.log_json%type,
                          p_tipo     in auditor.log_system.tipo%type default null,
                          p_titulo   in auditor.log_system.titulo%type default null,
                          p_origen   in auditor.log_system.origen%type default null                          
                         ) IS

v_app_id            auditor.log_system.app_id%type         := trim(p_app_id); 
v_tipo              auditor.log_system.tipo%type           := trim(p_tipo); 
v_titulo            auditor.log_system.titulo%type         := trim(p_titulo); 
v_origen            auditor.log_system.origen%type ;        --:= trim(p_origen); 
v_log_json          auditor.log_system.log_json%type       := trim(p_log_json); 
v_log_id            auditor.log_system.log_id%type         := p_log_id;

BEGIN

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    --Tipos
    --    1:Debug
    --    2:Info
    --    3:Error
    --    4:Warning

    --homologamos los [tipos de registros] que llegan por parametros    
    begin

        select id_item
        into v_tipo
        from generalidades.grl_referencia_item
        where id_referencia = v_id_referencia
        and valor_ext=decode(v_tipo,1,'DEBUG',2,'INFO',3,'ERROR',4,'WARNING','ERROR'); 

    exception when others then

        v_tipo := null;

    end;

    if pkg_validaciones.tamanio_campo(v_titulo,500) = false then
        v_titulo := substr(v_titulo,0,500);
    end if;


    if pkg_validaciones.tamanio_campo(v_origen,500) = false then
        v_origen := substr(v_origen,0,500);
    end if;

    insert into auditor.log_system(log_id, app_id, tipo, titulo, origen, log_json, fecha_reg) 
    values(v_log_id, v_app_id, v_tipo, v_titulo, p_origen, p_log_json, sysdate);

    commit;

END;                         

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
FUNCTION GENERA_LOG_ID RETURN NUMBER IS


begin 

    return auditor.seq_log_system_log_id.nextval;

end; 

end;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_LOG" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package Body PKG_PARAMETRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_PARAMETRO" IS
    --------------------------------------------------------------------------
    -- VARIABLES GLOBALES
    --------------------------------------------------------------------------
    v_idApp                     NUMBER := CONST.PARAM_ID_APP; -- ID del package

    ----------------------------------------
    -- INSERT
    ----------------------------------------
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
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
        v_idParametro           GRL_PARAMETRO.ID_PARAMETRO%TYPE;
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idSistemaParametro', p_idSistemaParametro, 'required|int'),
            VALIDATOR.RULE('idModuloParametro', p_idModuloParametro, 'required|int'),
            VALIDATOR.RULE('idAplicacionParametro', p_idAplicacionParametro, 'required|int'),
            VALIDATOR.RULE('nombreParametro', p_nombreParametro, 'required|string'),
            VALIDATOR.RULE('descripcionParametro', p_descripcionParametro, 'string'),
            VALIDATOR.RULE('valorParametro', p_valorParametro, 'required|string'),
            VALIDATOR.RULE('idTipoParametro', p_idTipoParametro, 'required|int'),
            VALIDATOR.RULE('idEstadoParametro', p_idEstadoParametro, 'required|int'),
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int'),
            VALIDATOR.RULE('idTipoDatoParametro', p_idTipoDatoParametro, 'required|int'),
            VALIDATOR.RULE('userRegParametro', p_userRegParametro, 'required|int')
        ));
        
        INSERT INTO GRL_PARAMETRO (ID_PARAMETRO, ID_SISTEMA, ID_MODULO, ID_APLICACION, NOMBRE, DESCRIPCION, VALOR, ID_TIPO, ID_ESTADO, ID_USUARIO, ID_TIPO_DATO, FECHA_REG, USER_REG)
        VALUES (GRL_PARAMETRO_SEQ.NEXTVAL, p_idSistemaParametro, p_idModuloParametro, p_idAplicacionParametro, p_nombreParametro, p_descripcionParametro, p_valorParametro, p_idTipoParametro, p_idEstadoParametro, p_idUsuarioParametro, p_idTipoDatoParametro, SYSDATE, p_userRegParametro)
        RETURNING ID_PARAMETRO INTO v_idParametro;

        OPEN p_cursor FOR SELECT v_idParametro AS "uid", CONST.MSG_INSERT_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'v_idParametro' VALUE v_idParametro, 'idSistemaParametro' VALUE p_idSistemaParametro, 'idModuloParametro' VALUE p_idModuloParametro, 'idAplicacionParametro' VALUE p_idAplicacionParametro, 'nombreParametro' VALUE p_nombreParametro, 
                                'descripcionParametro' VALUE p_descripcionParametro, 'valorParametro' VALUE p_valorParametro, 'idTipoParametro' VALUE p_idTipoParametro, 'idEstadoParametro' VALUE p_idEstadoParametro, 'idUsuarioParametro' VALUE p_idUsuarioParametro, 
                                'idTipoDatoParametro' VALUE p_idTipoDatoParametro, 'userRegParametro' VALUE p_userRegParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END INSERT_PARAMETRO;

    ----------------------------------------
    -- UPDATE
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
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_message               VARCHAR2(100) := CONST.MSG_UPDATE_OK;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idParametroParametro', p_idParametroParametro, 'required|int'),
            VALIDATOR.RULE('idSistemaParametro', p_idSistemaParametro, 'required|int'),
            VALIDATOR.RULE('idModuloParametro', p_idModuloParametro, 'required|int'),
            VALIDATOR.RULE('idAplicacionParametro', p_idAplicacionParametro, 'required|int'),
            VALIDATOR.RULE('nombreParametro', p_nombreParametro, 'required|string'),
            VALIDATOR.RULE('descripcionParametro', p_descripcionParametro, 'string'),
            VALIDATOR.RULE('valorParametro', p_valorParametro, 'required|string'),
            VALIDATOR.RULE('idTipoParametro', p_idTipoParametro, 'required|int'),
            VALIDATOR.RULE('idEstadoParametro', p_idEstadoParametro, 'required|int'),
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int'),
            VALIDATOR.RULE('idTipoDatoParametro', p_idTipoDatoParametro, 'required|int'),
            VALIDATOR.RULE('userRegParametro', p_userRegParametro, 'required|int')
        ));

        UPDATE  GRL_PARAMETRO SET 
                ID_SISTEMA = NVL(p_idSistemaParametro, ID_SISTEMA),
                ID_MODULO = NVL(p_idModuloParametro, ID_MODULO),
                ID_APLICACION = NVL(p_idAplicacionParametro, ID_APLICACION),
                NOMBRE = NVL(p_nombreParametro, NOMBRE),
                DESCRIPCION = NVL(p_descripcionParametro, DESCRIPCION),
                VALOR = NVL(p_valorParametro, VALOR),
                ID_TIPO = NVL(p_idTipoParametro, ID_TIPO),
                ID_ESTADO = NVL(p_idEstadoParametro, ID_ESTADO),
                ID_USUARIO = NVL(p_idUsuarioParametro, ID_USUARIO),
                ID_TIPO_DATO = NVL(p_idTipoDatoParametro, ID_TIPO_DATO),
                FECHA_REG = SYSDATE,
                USER_REG = NVL(p_userRegParametro, USER_REG)
        WHERE   ID_PARAMETRO = p_idParametroParametro
                AND (
                    DECODE(ID_SISTEMA, NVL(p_idSistemaParametro, ID_SISTEMA), 0, 1) = 1 OR
                    DECODE(ID_MODULO, NVL(p_idModuloParametro, ID_MODULO), 0, 1) = 1 OR
                    DECODE(ID_APLICACION, NVL(p_idAplicacionParametro, ID_APLICACION), 0, 1) = 1 OR
                    DECODE(NOMBRE, NVL(p_nombreParametro, NOMBRE), 0, 1) = 1 OR
                    DECODE(DESCRIPCION, NVL(p_descripcionParametro, DESCRIPCION), 0, 1) = 1 OR
                    DECODE(VALOR, NVL(p_valorParametro, VALOR), 0, 1) = 1 OR
                    DECODE(ID_TIPO, NVL(p_idTipoParametro, ID_TIPO), 0, 1) = 1 OR
                    DECODE(ID_ESTADO, NVL(p_idEstadoParametro, ID_ESTADO), 0, 1) = 1 OR
                    DECODE(ID_USUARIO, NVL(p_idUsuarioParametro, ID_USUARIO), 0, 1) = 1 OR
                    DECODE(ID_TIPO_DATO, NVL(p_idTipoDatoParametro, ID_TIPO_DATO), 0, 1) = 1
                );

        IF SQL%ROWCOUNT = 0 THEN
            v_message := CONST.MSG_NO_ROWS_AFFECTED;
        END IF;

        OPEN p_cursor FOR SELECT p_idParametroParametro AS "uid", CONST.MSG_UPDATE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'idParametroParametro' VALUE p_idParametroParametro, 'idSistemaParametro' VALUE p_idSistemaParametro, 'idModuloParametro' VALUE p_idModuloParametro, 'idAplicacionParametro' VALUE p_idAplicacionParametro, 'nombreParametro' VALUE p_nombreParametro, 
                                'descripcionParametro' VALUE p_descripcionParametro, 'valorParametro' VALUE p_valorParametro, 'idTipoParametro' VALUE p_idTipoParametro, 'idEstadoParametro' VALUE p_idEstadoParametro, 'idUsuarioParametro' VALUE p_idUsuarioParametro, 
                                'idTipoDatoParametro' VALUE p_idTipoDatoParametro, 'userRegParametro' VALUE p_userRegParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END UPDATE_PARAMETRO;

    ----------------------------------------
    -- DELETE LOGICO
    ----------------------------------------
    PROCEDURE DELETE_LOGICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idParametroParametro', p_idParametroParametro, 'required|int'),
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int'),
            VALIDATOR.RULE('userRegParametro', p_userRegParametro, 'required|int')
        ));

        UPDATE  GRL_PARAMETRO
        SET     ID_ESTADO = CONST.PARAM_ESTADO_ELIMINADO,
                FECHA_REG = SYSDATE,
                USER_REG = NVL(p_userRegParametro, USER_REG)
        WHERE   ID_PARAMETRO = p_idParametroParametro
                AND ID_USUARIO = p_idUsuarioParametro
                AND ID_ESTADO <> CONST.PARAM_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idParametroParametro||'-'||p_idUsuarioParametro AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'idParametroParametro' VALUE p_idParametroParametro, 'idUsuarioParametro' VALUE p_idUsuarioParametro, 'userRegParametro' VALUE p_userRegParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END DELETE_LOGICO_PARAMETRO;

    ----------------------------------------
    -- DELETE FISICO
    ----------------------------------------
    PROCEDURE DELETE_FISICO_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_userRegParametro      IN GRL_PARAMETRO.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idParametroParametro', p_idParametroParametro, 'required|int'),
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int'),
            VALIDATOR.RULE('userRegParametro', p_userRegParametro, 'required|int')
        ));

        DELETE_LOGICO_PARAMETRO(p_idParametroParametro, p_idUsuarioParametro, p_userRegParametro, p_cursor);

        DELETE FROM GRL_PARAMETRO
        WHERE ID_PARAMETRO = p_idParametroParametro
        AND ID_ESTADO = CONST.PARAM_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idParametroParametro||'-'||p_idUsuarioParametro AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'idParametroParametro' VALUE p_idParametroParametro, 'idUsuarioParametro' VALUE p_idUsuarioParametro, 'p_userRegParametro' VALUE p_userRegParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END DELETE_FISICO_PARAMETRO;

    ----------------------------------------------------
    -- SELECT por ID
    ----------------------------------------------------
    PROCEDURE GETBYID_PARAMETRO (
        p_idParametroParametro  IN GRL_PARAMETRO.ID_PARAMETRO%TYPE,
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idParametroParametro', p_idParametroParametro, 'required|int'),
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT  p.ID_PARAMETRO                      AS "idParametroParametro", 
                    p.ID_SISTEMA                        AS "idSistemaParametro", 
                    UPPER(sist.SIS_NOMBRE)              AS "nombreSistemaParametro",
                    p.ID_MODULO                         AS "idModuloParametro", 
                    p.ID_APLICACION                     AS "idAplicacionParametro",
                    UPPER(app.APP_NOMBRE)               AS "nombreAplicacionParametro",
                    p.NOMBRE                            AS "nombreParametro", 
                    p.DESCRIPCION                       AS "descripcionParametro", 
                    p.VALOR                             AS "valorParametro", 
                    p.ID_TIPO                           AS "idTipoParametro", 
                    tipo.NOMBRE                         AS "nombreTipoParametro", 
                    p.ID_ESTADO                         AS "idEstadoParametro", 
                    estado.NOMBRE                       AS "nombreEstadoParametro",
                    p.ID_USUARIO                        AS "idUsuarioParametro",
                    p.ID_TIPO_DATO                      AS "idTipoDatoParametro",
                    tdato.NOMBRE                        AS "nombreTipoDatoParametro",
                    TO_CHAR(p.FECHA_REG, 'DD-MM-YYYY')  AS "fechaRegParametro",
                    p.USER_REG                          AS "userRegParametro"
            FROM    GRL_REFERENCIA_ITEM tipo, GRL_REFERENCIA_ITEM estado, GRL_REFERENCIA_ITEM tdato, GRL_PARAMETRO p, SIGESUSTIC.SGU_SISTEMA sist, SIGESUSTIC.SGU_APLICACION app
            WHERE   tipo.ID_ITEM = p.ID_TIPO
                    AND estado.ID_ITEM = p.ID_ESTADO
                    AND tdato.ID_ITEM = p.ID_TIPO_DATO
                    AND p.ID_SISTEMA = sist.SIS_ID
                    AND p.ID_APLICACION = app.APP_ID
                    AND p.ID_PARAMETRO = p_idParametroParametro
                    AND p.ID_USUARIO = p_idUsuarioParametro;
    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'idParametroParametro' VALUE p_idParametroParametro, 'idUsuarioParametro' VALUE p_idUsuarioParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END GETBYID_PARAMETRO;

    ---------------------------------------------------------------------------------------
    -- SELECT todos
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALL_PARAMETRO (
        p_idUsuarioParametro    IN GRL_PARAMETRO.ID_USUARIO%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(512);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('idUsuarioParametro', p_idUsuarioParametro, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT  p.ID_PARAMETRO                      AS "idParametroParametro", 
                    p.ID_SISTEMA                        AS "idSistemaParametro", 
                    UPPER(sist.SIS_NOMBRE)              AS "nombreSistemaParametro",
                    p.ID_MODULO                         AS "idModuloParametro", 
                    p.ID_APLICACION                     AS "idAplicacionParametro",
                    UPPER(app.APP_NOMBRE)               AS "nombreAplicacionParametro",
                    p.NOMBRE                            AS "nombreParametro", 
                    p.DESCRIPCION                       AS "descripcionParametro", 
                    p.VALOR                             AS "valorParametro", 
                    p.ID_TIPO                           AS "idTipoParametro", 
                    tipo.NOMBRE                         AS "nombreTipoParametro", 
                    p.ID_ESTADO                         AS "idEstadoParametro", 
                    estado.NOMBRE                       AS "nombreEstadoParametro",
                    p.ID_USUARIO                        AS "idUsuarioParametro", 
                    p.ID_TIPO_DATO                      AS "idTipoDatoParametro", 
                    tdato.NOMBRE                        AS "nombreTipoDatoParametro",
                    TO_CHAR(p.FECHA_REG, 'DD-MM-YYYY')  AS "fechaRegParametro",
                    p.USER_REG                          AS "userRegParametro"
            FROM    GRL_REFERENCIA_ITEM tipo, GRL_REFERENCIA_ITEM estado, GRL_REFERENCIA_ITEM tdato, GRL_PARAMETRO p, SIGESUSTIC.SGU_SISTEMA sist, SIGESUSTIC.SGU_APLICACION app
            WHERE   tipo.ID_ITEM = p.ID_TIPO
                    AND estado.ID_ITEM = p.ID_ESTADO
                    AND tdato.ID_ITEM = p.ID_TIPO_DATO
                    AND p.ID_SISTEMA = sist.SIS_ID
                    AND p.ID_APLICACION = app.APP_ID
                    AND p.ID_USUARIO = p_idUsuarioParametro
            ORDER   BY p.NOMBRE;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorcode := SQLCODE;
            v_errormessage := SQLERRM;
            SELECT JSON_OBJECT( 'idUsuarioParametro' VALUE p_idUsuarioParametro, 'ora-error' VALUE v_errorcode, 'ora-msg' VALUE v_errormessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END GETALL_PARAMETRO;

END PKG_PARAMETRO;

/
--------------------------------------------------------
--  DDL for Package Body PKG_PERSONA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_PERSONA" AS

    -- ERRORES
    C_INDICES_DUPLICADOS CONSTANT VARCHAR2(2) := '1';
    E_DATO_DUPLICADO CONSTANT number := 20008; --Dato duplicado
    E_ERROR_INSERCION CONSTANT number := 20005; --Error en la inserci�n
    ----------

    c_idApp CONSTANT NUMBER := 101;     -- ID del package
    c_origen CONSTANT auditor.log_system.origen%type := 'GENERALIDADES.PKG_PERSONA';
    C_DEBUG CONSTANT generalidades.grl_referencia_item.id_item%TYPE := 1681;
    C_INFO	CONSTANT generalidades.grl_referencia_item.id_item%TYPE := 1682;
    C_ERROR	CONSTANT generalidades.grl_referencia_item.id_item%TYPE := 1683;
    C_WARNING CONSTANT generalidades.grl_referencia_item.id_item%TYPE := 1684;


    c_id_refe_tipo_id CONSTANT NUMBER := 23;
    c_id_refe_sexos CONSTANT NUMBER := 26;
    c_id_refe_genero CONSTANT NUMBER := 22;
    c_id_refe_nacionalidad CONSTANT NUMBER := 24;
    c_id_refe_estado_civil CONSTANT NUMBER := null;
    c_id_refe_situac_militar CONSTANT NUMBER := null;
    c_id_refe_tipo_direccion CONSTANT NUMBER := 25;
    c_id_refe_direccion CONSTANT NUMBER := null;
    c_id_refe_comuna CONSTANT NUMBER := null;
    c_id_refe_region CONSTANT NUMBER := null;
    c_id_refe_clase_direccion CONSTANT NUMBER := 27;

    PROCEDURE GET_ALL (
        p_id IN NUMBER DEFAULT NULL,
        p_rut IN VARCHAR2 DEFAULT NULL,
        p_cursor OUT CLOB
    )
    IS    

    BEGIN

        with persona_tipo_direccion as (
            select  id_persona, id_tipo
            FROM grl_persona_direccion            
            group by id_persona, id_tipo
        ),
        persona_direcciones as (
            select perdir.id_persona, perdir.id_tipo, perdir.id_direccion,
            dir.CALLE, dir.NUMERO, dir.DEPTO, dir.ID_COMUNA,dir.ID_REGION, 
            dir.ID_CLASE_DIRECCION, dir.LATITUD, dir.LONGITUD, dir.COD_POSTAL, dir.CIUDAD, dir.ID_PAIS
            from grl_persona_direccion perdir
            left join grl_direccion dir on perdir.id_direccion=dir.id_direccion
        ),        
        referencias as (
            select id_item, nombre
            from grl_referencia_item
            where id_referencia in (
                c_id_refe_tipo_id,
                c_id_refe_sexos,
                c_id_refe_genero,
                c_id_refe_nacionalidad,
                c_id_refe_estado_civil,
                c_id_refe_situac_militar,
                c_id_refe_tipo_direccion,
                c_id_refe_direccion,
                c_id_refe_comuna,
                c_id_refe_region,
                c_id_refe_clase_direccion
            )
        )
        SELECT JSON_ARRAYAGG( JSON_OBJECT(
                'id_persona' VALUE per.ID_PERSONA,
                'identificador' VALUE per.IDENTIFICADOR, 
                'id_tipo_id' VALUE per.ID_TIPO_ID,
                'tipo_id' VALUE (
                    select nombre from referencias where id_item = per.ID_TIPO_ID
                ),
                'nombres' VALUE INITCAP(per.NOMBRES), 
                'primer_apellido' VALUE INITCAP(per.PRIMER_APELLIDO), 
                'segundo_apellido' VALUE INITCAP(per.SEGUNDO_APELLIDO), 
                'fecha_nac' VALUE TO_CHAR(per.FECHA_NAC, 'DD/MM/YYYY'), 
                'nombre_social' VALUE INITCAP(per.NOMBRE_SOCIAL), 
                'id_sexo' VALUE per.ID_SEXO,
                'sexo' VALUE (
                    select nombre from referencias where id_item = per.ID_SEXO
                ),
                'id_genero' VALUE per.ID_GENERO,
                'genero' VALUE (
                    select nombre from referencias where id_item = per.ID_GENERO
                ),
                'otro_genero' VALUE per.OTRO_GENERO, 
                'con_discapacidad' VALUE per.CON_DISCAPACIDAD, 
                'discapacidad' VALUE per.DISCAPACIDAD, 
                'id_nacionalidad' VALUE per.ID_NACIONALIDAD,
                'nacionalidad' VALUE (
                    select nombre from referencias where id_item = per.ID_NACIONALIDAD
                ),
                'fallecido' VALUE per.FALLECIDO,
                'celular' VALUE dat.celular, 
                'fono' VALUE dat.fono, 
                'email' VALUE dat.email,
                'id_estado_civil' VALUE dat.id_estado_civil,
                'estado_civil' VALUE (
                    select nombre from referencias where id_item = dat.id_estado_civil
                ),
                'id_situac_militar' VALUE dat.id_situac_militar,
                'situac_militar' VALUE (
                    select nombre from referencias where id_item = dat.id_situac_militar
                ),
                'tipo_direccion' VALUE ( 
                    SELECT JSON_ARRAYAGG(
                        JSON_OBJECT(                            
                            'id_tipo' VALUE tipodir.id_tipo,
                            'tipo' VALUE (
                                select nombre from referencias where id_item = tipodir.id_tipo
                            ),                            
                            'direcciones' VALUE (
                                SELECT JSON_ARRAYAGG(
                                    JSON_OBJECT(
                                        'id_direccion' VALUE perdir.id_direccion,
                                        'calle' VALUE perdir.calle,
                                        'numero' VALUE perdir.numero,
                                        'depto' VALUE perdir.depto,
                                        'id_comuna' VALUE perdir.id_comuna,
                                        'id_region' VALUE perdir.id_region,
                                        'id_clase_direccion' VALUE perdir.id_clase_direccion,
                                        'latitud' VALUE perdir.latitud,
                                        'longitud' VALUE perdir.longitud,
                                        'cod_postal' VALUE perdir.cod_postal,
                                        'ciudad' VALUE perdir.ciudad,
                                        'id_pais' VALUE perdir.id_pais,
                                        'pais' VALUE (
                                            select nombre from referencias where id_item = perdir.id_pais
                                        )
                                    )
                                )
                                from persona_direcciones perdir
                                where perdir.id_persona=tipodir.id_persona
                                and perdir.id_tipo=tipodir.id_tipo
                            )

                            --RETURNING CLOB
                        ) --RETURNING CLOB
                    )
                    from persona_tipo_direccion tipodir
                    WHERE tipodir.id_persona = per.id_persona
                )

                RETURNING CLOB
                ) RETURNING CLOB )
        INTO p_cursor
        FROM GRL_PERSONA per
        LEFT JOIN grl_persona_dato_personal dat ON per.ID_PERSONA=dat.ID_PERSONA
        --LEFT JOIN persona_direccion perdir ON per.ID_PERSONA=perdir.ID_PERSONA
        WHERE (p_id IS NOT NULL AND per.id_persona = p_id)
        OR (p_id IS NULL AND per.identificador = p_rut)
        OR (p_id IS NULL AND p_rut IS NULL)
        and      
        ROWNUM <= 10000
        ;


    END GET_ALL;

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
    )
    IS   
    BEGIN
        INSERT INTO GRL_PERSONA (IDENTIFICADOR, ID_TIPO_ID, NOMBRES, PRIMER_APELLIDO, 
        SEGUNDO_APELLIDO, FECHA_NAC, NOMBRE_SOCIAL, ID_SEXO, ID_GENERO, OTRO_GENERO, CON_DISCAPACIDAD, 
        DISCAPACIDAD, ID_NACIONALIDAD, FALLECIDO, ID_USUARIO_MOD, FEC_ULT_MOD)
        VALUES (P_IDENTIFICADOR, P_ID_TIPO_ID, P_NOMBRES, P_PRIMER_APELLIDO, P_SEGUNDO_APELLIDO, P_FECHA_NAC, 
        P_NOMBRE_SOCIAL, P_ID_SEXO, P_ID_GENERO, P_OTRO_GENERO, P_CON_DISCAPACIDAD, P_DISCAPACIDAD, P_ID_NACIONALIDAD, 
        P_FALLECIDO, P_ID_USUARIO_MOD, SYSDATE)        
        RETURNING ID_PERSONA INTO O_ID_PERSONA;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-E_DATO_DUPLICADO, '(PKG_PERSONA.INSERT_GRL_PERSONA) Registro duplicado' || ': ' || SQLERRM_SIN_CODIGO(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE), FALSE);
            ROLLBACK;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-E_ERROR_INSERCION, SQLERRM_SIN_CODIGO(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE), FALSE);           
            ROLLBACK;        
    END INSERT_GRL_PERSONA;

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
    )
    IS
    BEGIN
        INSERT INTO GRL_PERSONA_DATO_PERSONAL (ID_PERSONA, CELULAR, FONO, EMAIL, FEC_ULT_ACT, ID_ESTADO_CIVIL, ID_SITUAC_MILITAR, 
        ID_USUARIO_MOD, FEC_ULT_MOD)
        VALUES (P_ID_PERSONA,P_CELULAR,P_FONO,P_EMAIL,P_FEC_ULT_ACT,P_ID_ESTADO_CIVIL,P_ID_SITUAC_MILITAR,P_ID_USUARIO_MOD,SYSDATE);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-E_DATO_DUPLICADO, SQLERRM_SIN_CODIGO(SQLERRM) || ': ' || SQLERRM_SIN_CODIGO(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE), FALSE);            
        WHEN OTHERS THEN            
            RAISE_APPLICATION_ERROR(-E_ERROR_INSERCION, '(PKG_PERSONA.INSERT_GRL_PERSONA_DATO_PERSONAL) Error en guardar datos' || ': ' || SQLERRM_SIN_CODIGO(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE), FALSE);
            ROLLBACK;
    END INSERT_GRL_PERSONA_DATO_PERSONAL;

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
    )
    IS
    BEGIN
        INSERT INTO GRL_DIRECCION ( CALLE, NUMERO, DEPTO, ID_COMUNA, ID_REGION, ID_CLASE_DIRECCION, LATITUD, LONGITUD, 
        COD_POSTAL, CIUDAD, ID_PAIS, FEC_ULT_ACT, ID_USUARIO_MOD)
        VALUES (P_CALLE,P_NUMERO,P_DEPTO,P_ID_COMUNA,P_ID_REGION,P_ID_CLASE_DIRECCION,P_LATITUD
                ,P_LONGITUD,P_COD_POSTAL,P_CIUDAD,P_ID_PAIS,P_FEC_ULT_ACT,P_ID_USUARIO_MOD)
        RETURNING ID_DIRECCION INTO O_ID_DIRECCION;

        IF SQL%ROWCOUNT > 0 THEN
            O_RESPUESTA := 'OK';
        ELSE
            O_RESPUESTA := 'ERROR';
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            O_RESPUESTA := 'ERROR: ' || SQLERRM;
            ROLLBACK;
    END INSERT_GRL_DIRECCION;

    PROCEDURE INSERT_GRL_PERSONA_DIRECCION (
        ID_PERSONA      IN NUMBER,    
        ID_DIRECCION    IN NUMBER,
        ID_TIPO         IN NUMBER,
        O_RESPUESTA     OUT VARCHAR2
    )
    IS
    BEGIN
        INSERT INTO GRL_PERSONA_DIRECCION (ID_PERSONA, ID_DIRECCION, ID_TIPO)
        VALUES (ID_PERSONA,ID_DIRECCION,ID_TIPO);

        IF SQL%ROWCOUNT > 0 THEN
            O_RESPUESTA := 'OK';
        ELSE
            O_RESPUESTA := 'ERROR';
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            O_RESPUESTA := 'ERROR: ' || SQLERRM;
            ROLLBACK;
    END INSERT_GRL_PERSONA_DIRECCION;

    FUNCTION MENSAJE_RETORNO (
        P_TIPO IN VARCHAR2,
        P_MENSAJE IN VARCHAR2
    ) RETURN SYS_REFCURSOR
    IS
        V_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN V_CURSOR FOR
            SELECT P_TIPO AS TIPO,
                   P_MENSAJE AS MENSAJE
            FROM DUAL;

        RETURN V_CURSOR;
    END;


    PROCEDURE GUARDAR_PERSONA (
        P_JSON      IN CLOB,
        P_CURSOR    OUT SYS_REFCURSOR
    )
    IS

      l_json JSON_OBJECT_T;

      l_direcciones JSON_ARRAY_T;
      l_direccion JSON_OBJECT_T;

      l_wrapper JSON_OBJECT_T;
      l_json_clob CLOB;

        v_log_json auditor.log_system.log_json%type;

        v_sqlerror varchar2(1000);
        v_sqlcode number;

        v_calle VARCHAR2(100);
        v_numero VARCHAR2(10);
        v_depto VARCHAR2(10);
        v_comuna NUMBER;
        v_region NUMBER;
        v_clase_direccion NUMBER;
        v_latitud NUMBER;
        v_longitud NUMBER;
        v_cod_postal VARCHAR2(10);
        v_ciudad VARCHAR2(20);
        v_pais NUMBER;
        v_fec_ult_act DATE;
        v_tipo NUMBER;


      -- Variables para datos principales
      v_identificador VARCHAR2(20);
      v_tipo_id NUMBER;
      v_nombres VARCHAR2(200);
      v_primer_apellido VARCHAR2(100);
      v_segundo_apellido VARCHAR2(100);
      v_fecha_nac DATE;
      v_nombre_social VARCHAR2(100);
      v_sexo NUMBER;
      v_genero NUMBER;
      v_otro_genero VARCHAR2(100);
      v_con_discapacidad CHAR(1);
      v_discapacidad VARCHAR2(500);
      v_nacionalidad NUMBER;
      v_fallecido CHAR(1);
      v_usuario_mod NUMBER;
      v_fec_ult_mod DATE;
      v_celular VARCHAR2(20);
      v_fono VARCHAR2(20);
      v_email VARCHAR2(200);
      v_estado_civil NUMBER;
      v_situac_militar NUMBER;

      v_id_persona number;
      v_respuesta varchar2(200);        
      v_id_direccion number;

    BEGIN        

        l_json := JSON_OBJECT_T.parse(P_JSON);
        l_direcciones := l_json.get_array('direcciones');      

      v_id_persona := 0;

      IF l_json.has('id_persona') THEN
          v_id_persona := l_json.get_string('id_persona');
      END IF;

      v_identificador := l_json.get_string('identificador');
      v_tipo_id := l_json.get_number('tipo_id');
      v_nombres := l_json.get_string('nombres');
      v_primer_apellido := l_json.get_string('primer_apellido');
      v_segundo_apellido := l_json.get_string('segundo_apellido');
      v_fecha_nac := TO_DATE(l_json.get_string('fecha_nac'), 'DD/MM/YYYY');
      v_nombre_social := l_json.get_string('nombre_social');
      v_sexo := l_json.get_number('sexo');
      v_genero := l_json.get_number('genero');
      v_otro_genero := l_json.get_string('otro_genero');
      v_con_discapacidad := l_json.get_string('con_discapacidad');
      v_discapacidad := l_json.get_string('discapacidad');
      v_nacionalidad := l_json.get_number('nacionalidad');
      v_fallecido := l_json.get_string('fallecido');
      v_usuario_mod := l_json.get_number('usuario_mod');
      v_fec_ult_mod := TO_DATE(l_json.get_string('fec_ult_mod'), 'DD/MM/YYYY');

      v_celular := l_json.get_string('celular');
      v_fono := l_json.get_string('fono');
      v_email := l_json.get_string('email');
      v_estado_civil := l_json.get_number('estado_civil');
      v_situac_militar := l_json.get_number('situac_militar');       


        IF v_id_persona = 0 THEN
            PKG_PERSONA.INSERT_GRL_PERSONA (
                P_IDENTIFICADOR     => v_identificador,
                P_ID_TIPO_ID        => v_tipo_id,
                P_NOMBRES           => v_nombres,
                P_PRIMER_APELLIDO   => v_primer_apellido,
                P_SEGUNDO_APELLIDO  => v_segundo_apellido,
                P_FECHA_NAC         => v_fecha_nac,
                P_NOMBRE_SOCIAL     => v_nombre_social,
                P_ID_SEXO           => v_sexo,
                P_ID_GENERO         => v_genero,
                P_OTRO_GENERO       => v_otro_genero,
                P_CON_DISCAPACIDAD  => v_con_discapacidad,
                P_DISCAPACIDAD      => v_discapacidad,
                P_ID_NACIONALIDAD   => v_nacionalidad,
                P_FALLECIDO         => v_fallecido,
                P_ID_USUARIO_MOD    => v_usuario_mod,
                P_FEC_ULT_MOD       => v_fec_ult_mod,
                O_ID_PERSONA        => v_id_persona
            );

            PKG_PERSONA.INSERT_GRL_PERSONA_DATO_PERSONAL (
                P_ID_PERSONA          => v_id_persona,
                P_CELULAR             => v_celular,
                P_FONO                => v_fono,
                P_EMAIL               => v_email,
                P_FEC_ULT_ACT         => SYSDATE,
                P_ID_ESTADO_CIVIL     => v_estado_civil,
                P_ID_SITUAC_MILITAR   => v_situac_militar,
                P_ID_USUARIO_MOD      => v_usuario_mod,
                P_FEC_ULT_MOD         => SYSDATE
            );        

             FOR i IN 0 .. l_direcciones.get_size - 1 LOOP
                l_direccion := JSON_OBJECT_T(l_direcciones.get(i));

                v_calle := l_direccion.get_string('calle');
                v_numero := l_direccion.get_string('numero');
                v_depto := l_direccion.get_string('depto');
                v_comuna := l_direccion.get_number('comuna');
                v_region := l_direccion.get_number('region');
                v_clase_direccion := l_direccion.get_number('clase_direccion');
                v_latitud := l_direccion.get_number('latitud');
                v_longitud := l_direccion.get_number('longitud');
                v_cod_postal := l_direccion.get_string('cod_postal');
                v_ciudad := l_direccion.get_string('ciudad');
                v_pais := l_direccion.get_number('pais');
                v_fec_ult_act := TO_DATE(l_direccion.get_string('fec_ult_act'), 'DD/MM/YYYY');
                v_tipo := l_direccion.get_number('tipo');

                PKG_PERSONA.INSERT_GRL_DIRECCION (        
                    P_CALLE                   => v_calle,
                    P_NUMERO                  => v_numero,
                    P_DEPTO                   => v_depto,
                    P_ID_COMUNA               => v_comuna,
                    P_ID_REGION               => v_region,
                    P_ID_CLASE_DIRECCION      => v_clase_direccion,
                    P_LATITUD                 => v_latitud,
                    P_LONGITUD                => v_longitud,
                    P_COD_POSTAL              => v_cod_postal,
                    P_CIUDAD                  => v_ciudad,
                    P_ID_PAIS                 => v_pais,
                    P_FEC_ULT_ACT             => v_fec_ult_act,
                    P_ID_USUARIO_MOD          => v_usuario_mod,
                    O_ID_DIRECCION            => v_id_direccion,
                    O_RESPUESTA               => v_respuesta
                );
                /*
                IF v_respuesta != 'OK' THEN
                    RAISE_APPLICATION_ERROR(-20003, 'ERROR EN GUARDAR DATOS ' || v_respuesta);
                END IF;
                */
                PKG_PERSONA.INSERT_GRL_PERSONA_DIRECCION (
                    ID_PERSONA      => v_id_persona,
                    ID_DIRECCION    => v_id_direccion,
                    ID_TIPO         => v_tipo,
                    O_RESPUESTA     => v_respuesta
                );
                /*
                IF v_respuesta != 'OK' THEN
                    RAISE_APPLICATION_ERROR(-20004, 'ERROR EN GUARDAR DATOS');
                END IF;
                */
              END LOOP;        
        END IF;

        OPEN p_cursor FOR
            SELECT 'OK' AS TIPO, v_id_persona AS ID FROM dual;

    EXCEPTION        
      WHEN OTHERS THEN
          ROLLBACK;
          l_wrapper := JSON_OBJECT_T();
          l_wrapper.put('P_JSON', l_json);
          l_json_clob := l_wrapper.to_clob();          

         PKG_LOG.REGISTRA_LOG(          
                        c_idApp,
                        C_ERROR, 
                        l_json_clob,
                        SQLERRM, 
                        c_origen || '.GUARDAR_PERSONA'
                      );
        v_sqlerror := SQLERRM;
        v_sqlcode := SQLCODE;
        OPEN P_CURSOR FOR
          SELECT 'ERROR' AS TIPO,
                   CASE 
                       WHEN v_sqlcode = -E_DATO_DUPLICADO THEN 'Registro duplicado'
                       WHEN v_sqlcode = -E_ERROR_INSERCION THEN 'Error en guardar datos'                       
                       ELSE SQLERRM_SIN_CODIGO(v_sqlerror)
                   END AS MENSAJE
            FROM DUAL;        
    END GUARDAR_PERSONA;    

    FUNCTION SQLERRM_SIN_CODIGO (
        P_SQLERRM IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TRIM(SUBSTR(P_SQLERRM, INSTR(P_SQLERRM, ':', 1) + 1));
    END SQLERRM_SIN_CODIGO;


    FUNCTION GETNOMBRE_PERSONA (
        p_id IN      grl_persona.id_persona%type, 
        p_formato in NUMBER DEFAULT NULL        
    ) RETURN varchar2 IS

    v_nombre varchar2(3000);

    BEGIN

        select case
               when p_formato is null then
                    segundo_apellido||' '||primer_apellido||' '||nombres
               when p_formato = 1 then
                    substr(nombres,1,decode(instr(nombres,' '),0,length(nombres),instr(nombres,' ')-1) )||' '||primer_apellido
               when p_formato = 2 then
                    nombres
               when p_formato = 3 then
                    segundo_apellido
               when p_formato = 4 then
                    primer_apellido
               when p_formato = 5 then
                    nombres||' '||primer_apellido||' '||segundo_apellido
               else
                    null
               end nombre
        into v_nombre 
        from grl_persona
        where id_persona = p_id;

        return v_nombre;

    EXCEPTION WHEN OTHERS THEN

        return null;

    END;

END PKG_PERSONA;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_PERSONA" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_PERSONA" TO "SIGESUSTIC";
--------------------------------------------------------
--  DDL for Package Body PKG_REFERENCIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_REFERENCIA" IS
    --------------------------------------------------------------------------
    -- VARIABLES GLOBALES
    --------------------------------------------------------------------------
    v_idApp                     CONSTANT NUMBER := CONST.REF_ID_APP; -- ID del package

    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE INSERT_REFERENCIA (
        p_nombre                IN GRL_REFERENCIA.NOMBRE%TYPE,
        p_descripcion           IN GRL_REFERENCIA.DESCRIPCION%TYPE,
        p_idTipo                IN GRL_REFERENCIA.ID_TIPO%TYPE,
        p_idClase               IN GRL_REFERENCIA.ID_CLASE%TYPE,
        p_idEstado              IN GRL_REFERENCIA.ID_ESTADO%TYPE,
        p_userReg               IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_idReferencia          GRL_REFERENCIA.ID_REFERENCIA%TYPE;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('nombre', p_nombre, 'required|string'),
            VALIDATOR.RULE('descripcion', p_descripcion, 'required|string'),
            VALIDATOR.RULE('id_tipo', p_idTipo, 'int'),
            VALIDATOR.RULE('id_clase', p_idClase, 'int'),
            VALIDATOR.RULE('id_estado', p_idEstado, 'int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        INSERT INTO GRL_REFERENCIA (ID_REFERENCIA, NOMBRE, DESCRIPCION, ID_TIPO, ID_CLASE, ID_ESTADO, FECHA_REG, USER_REG)
        VALUES (GRL_REFERENCIA_SEQ.NEXTVAL, p_nombre, p_descripcion, p_idTipo, p_idClase, p_idEstado, SYSDATE, p_userReg)
        RETURNING ID_REFERENCIA INTO v_idReferencia;

        OPEN p_cursor FOR SELECT v_idReferencia AS "uid", CONST.MSG_INSERT_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'v_idReferencia'    VALUE v_idReferencia,
                    'p_nombre'          VALUE p_nombre,
                    'p_descripcion'     VALUE p_descripcion,
                    'p_idTipo'          VALUE p_idTipo,
                    'p_idClase'         VALUE p_idClase,
                    'p_idEstado'        VALUE p_idEstado,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END INSERT_REFERENCIA;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE UPDATE_REFERENCIA (
        p_idReferencia          IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_nombre                IN GRL_REFERENCIA.NOMBRE%TYPE,
        p_descripcion           IN GRL_REFERENCIA.DESCRIPCION%TYPE,
        p_idTipo                IN GRL_REFERENCIA.ID_TIPO%TYPE,
        p_idClase               IN GRL_REFERENCIA.ID_CLASE%TYPE,
        p_idEstado              IN GRL_REFERENCIA.ID_ESTADO%TYPE,
        p_userReg               IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_message               VARCHAR2(100) := CONST.MSG_UPDATE_OK;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('nombre', p_nombre, 'required|string'),
            VALIDATOR.RULE('descripcion', p_descripcion, 'required|string'),
            VALIDATOR.RULE('id_tipo', p_idTipo, 'int'),
            VALIDATOR.RULE('id_clase', p_idClase, 'int'),
            VALIDATOR.RULE('id_estado', p_idEstado, 'int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        UPDATE  GRL_REFERENCIA
        SET     NOMBRE          = NVL(p_nombre, NOMBRE),
                DESCRIPCION     = NVL(p_descripcion, DESCRIPCION),
                ID_TIPO         = NVL(p_idTipo, ID_TIPO),
                ID_CLASE        = NVL(p_idClase, ID_CLASE),
                ID_ESTADO       = NVL(p_idEstado, ID_ESTADO),
                FECHA_REG  = SYSDATE,
                USER_REG        = NVL(p_userReg, USER_REG)
        WHERE   ID_REFERENCIA   = p_idReferencia
                AND ( 
                    DECODE(NOMBRE, NVL(p_nombre, NOMBRE), 0, 1) = 1 OR
                    DECODE(DESCRIPCION, NVL(p_descripcion, DESCRIPCION), 0, 1) = 1 OR
                    DECODE(ID_TIPO, NVL(p_idTipo, ID_TIPO), 0, 1) = 1 OR
                    DECODE(ID_CLASE, NVL(p_idClase, ID_CLASE), 0, 1) = 1 OR
                    DECODE(ID_ESTADO, NVL(p_idEstado, ID_ESTADO), 0, 1) = 1 OR
                    DECODE(USER_REG, NVL(p_userReg, USER_REG), 0, 1) = 1
                );

        IF SQL%ROWCOUNT = 0 THEN
            v_message := CONST.MSG_NO_ROWS_AFFECTED;
        END IF;

        OPEN p_cursor FOR SELECT p_idReferencia AS "uid", CONST.MSG_UPDATE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'p_nombre'          VALUE p_nombre,
                    'p_descripcion'     VALUE p_descripcion,
                    'p_idTipo'          VALUE p_idTipo,
                    'p_idClase'         VALUE p_idClase,
                    'p_idEstado'        VALUE p_idEstado,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END UPDATE_REFERENCIA;

    ----------------------------------------
    -- DELETE LOGICO
    ----------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIA (
        p_idReferencia          IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_userReg               IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        UPDATE  GRL_REFERENCIA
        SET     ID_ESTADO = CONST.REF_ESTADO_ELIMINADO,
                USER_REG = p_userReg
        WHERE   ID_REFERENCIA = p_idReferencia
                AND ID_ESTADO <> CONST.REF_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idReferencia AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

    END DELETE_LOGICO_REFERENCIA;

    ----------------------------------------
    -- DELETE FISICO
    ----------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIA (
        p_idReferencia          IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_userReg               IN GRL_REFERENCIA.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        DELETE_LOGICO_REFERENCIA(p_idReferencia, p_userReg, p_cursor);

        DELETE FROM GRL_REFERENCIA
        WHERE ID_REFERENCIA = p_idReferencia
        AND ID_ESTADO = CONST.REF_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idReferencia AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_id_referencia'   VALUE p_idReferencia,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END DELETE_FISICO_REFERENCIA;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GETBYID_REFERENCIA (
        p_idReferencia          IN GRL_REFERENCIA.ID_REFERENCIA%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT  ID_REFERENCIA                           AS "idReferencia", 
                    NOMBRE                                  AS "nombreReferencia", 
                    DESCRIPCION                             AS "descripcionReferencia", 
                    ID_TIPO                                 AS "idTipoReferencia", 
                    ID_CLASE                                AS "idClaseReferencia", 
                    ID_ESTADO                               AS "idEstadoReferencia", 
                    TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferencia",
                    USER_REG                                AS "userRegReferencia"
            FROM    GRL_REFERENCIA
            WHERE   ID_REFERENCIA = p_idReferencia;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETBYID_REFERENCIA;

    ----------------------------------------
    -- SELECT todos
    ----------------------------------------
    PROCEDURE GETALL_REFERENCIA (
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        OPEN p_cursor FOR
            SELECT  ID_REFERENCIA                           AS "idReferencia", 
                    NOMBRE                                  AS "nombreReferencia", 
                    DESCRIPCION                             AS "descripcionReferencia", 
                    ID_TIPO                                 AS "idTipoReferencia", 
                    ID_CLASE                                AS "idClaseReferencia", 
                    ID_ESTADO                               AS "idEstadoReferencia", 
                    TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferencia",
                    USER_REG                                AS "userRegReferencia"
            FROM    GRL_REFERENCIA
            ORDER   BY ID_REFERENCIA;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETALL_REFERENCIA;

END PKG_REFERENCIA;

/
--------------------------------------------------------
--  DDL for Package Body PKG_REFERENCIA_ITEM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_REFERENCIA_ITEM" IS
    --------------------------------------------------------------------------
    -- VARIABLES GLOBALES
    --------------------------------------------------------------------------
    v_idApp                     CONSTANT NUMBER := CONST.REF_ITEM_ID_APP; -- ID del package
    v_idClase                   CONSTANT NUMBER := CONST.REF_ITEM_ESTADO_JERARQUICA;
    ----------------------------------------
    -- INSERT
    ----------------------------------------
    PROCEDURE INSERT_REFERENCIAITEM (
        p_idReferencia          IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nombre                IN GRL_REFERENCIA_ITEM.NOMBRE%TYPE,
        p_valorExt              IN GRL_REFERENCIA_ITEM.VALOR_EXT%TYPE,
        p_idTipoDato            IN GRL_REFERENCIA_ITEM.ID_TIPO_DATO%TYPE,
        p_nivel                 IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_idPadre               IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_idEstado              IN GRL_REFERENCIA_ITEM.ID_ESTADO%TYPE,
        p_userReg               IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
        v_nivel                 NUMBER;
        v_idItem                GRL_REFERENCIA_ITEM.ID_ITEM%TYPE;
        v_notNull               EXCEPTION;
        PRAGMA EXCEPTION_INIT(v_notNull, -1400);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('nombre', p_nombre, 'required|string'),
            VALIDATOR.RULE('valor_ext', p_valorExt, 'string|default:null'),
            VALIDATOR.RULE('id_tipo_dato', p_idTipoDato, 'string'),
            VALIDATOR.RULE('nivel', p_nivel, 'required|int'),
            VALIDATOR.RULE('id_padre', p_idPadre, 'int'),
            VALIDATOR.RULE('id_estado', p_idEstado, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        IF p_nivel > 1 AND p_idPadre IS NOT NULL THEN
            SELECT NIVEL
            INTO v_nivel
            FROM GRL_REFERENCIA_ITEM
            WHERE ID_ITEM = p_idPadre;

            IF (v_nivel + 1) <> p_nivel THEN
                RAISE_APPLICATION_ERROR(-20006, 'El nivel ingresado no corresponde');
            END IF;
        END IF;

        INSERT INTO GRL_REFERENCIA_ITEM (ID_ITEM, ID_REFERENCIA, NOMBRE, VALOR_EXT, ID_TIPO_DATO, NIVEL, ID_PADRE, ID_ESTADO, FECHA_REG, USER_REG)
        VALUES (GRL_REFERENCIA_ITEM_SEQ.NEXTVAL, p_idReferencia, p_nombre, p_valorExt, p_idTipoDato, p_nivel, p_idPadre, p_idEstado, SYSDATE, p_userReg)
        RETURNING ID_ITEM INTO v_idItem;

        OPEN p_cursor FOR SELECT v_idItem AS "uid", CONST.MSG_INSERT_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN v_notNull THEN
            RAISE_APPLICATION_ERROR(-20005, 'Existen campos obligatorios sin valor.');
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT( 'v_idItem' VALUE v_idItem, 'p_idReferencia' VALUE p_idReferencia, 'p_nombre' VALUE p_nombre, 'p_valorExt' VALUE p_valorExt, 'p_idTipoDato' VALUE p_idTipoDato, 'p_nivel' VALUE p_nivel, 'p_idPadre' VALUE p_idPadre, 
                                'p_idEstado' VALUE p_idEstado, 'p_userReg' VALUE p_userReg, 'ora-error' VALUE v_errorCode, 'ora-msg' VALUE v_errorMessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB ) 
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT( 'v_idItem' VALUE v_idItem, 'p_idReferencia' VALUE p_idReferencia, 'p_nombre' VALUE p_nombre, 'p_valorExt' VALUE p_valorExt, 'p_idTipoDato' VALUE p_idTipoDato, 'p_nivel' VALUE p_nivel, 'p_idPadre' VALUE p_idPadre, 
                                'p_idEstado' VALUE p_idEstado, 'p_userReg' VALUE p_userReg, 'ora-error' VALUE v_errorCode, 'ora-msg' VALUE v_errorMessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB ) 
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END INSERT_REFERENCIAITEM;

    ----------------------------------------
    -- UPDATE
    ----------------------------------------
    PROCEDURE UPDATE_REFERENCIAITEM (
        p_idItem                IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_idReferencia          IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nombre                IN GRL_REFERENCIA_ITEM.NOMBRE%TYPE,
        p_valorExt              IN GRL_REFERENCIA_ITEM.VALOR_EXT%TYPE,
        p_idTipoDato            IN GRL_REFERENCIA_ITEM.ID_TIPO_DATO%TYPE,
        p_nivel                 IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_idPadre               IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_idEstado              IN GRL_REFERENCIA_ITEM.ID_ESTADO%TYPE,
        p_userReg               IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_message               VARCHAR2(100) := CONST.MSG_UPDATE_OK;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
        v_nivel                 NUMBER;
        v_notNull               EXCEPTION;
        v_fkParentMissing       EXCEPTION;
        PRAGMA EXCEPTION_INIT(v_notNull, -1400);
        PRAGMA EXCEPTION_INIT(v_fkParentMissing, -2291);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_item', p_idItem, 'required|int'),
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('nombre', p_nombre, 'required|string'),
            VALIDATOR.RULE('id_tipo_dato', p_idTipoDato, 'required|string'),
            VALIDATOR.RULE('nivel', p_nivel, 'required|int'),
            VALIDATOR.RULE('id_padre', p_idPadre, 'int'),
            VALIDATOR.RULE('id_estado', p_idEstado, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        IF p_nivel > 1 AND p_idPadre IS NOT NULL THEN
            SELECT nivel
            INTO v_nivel
            FROM GRL_REFERENCIA_ITEM
            WHERE id_item = p_idPadre;

            IF (v_nivel + 1) <> p_nivel THEN
                RAISE_APPLICATION_ERROR(-20006, 'El nivel ingresado no corresponde');
            END IF;
        END IF;

        UPDATE  GRL_REFERENCIA_ITEM
        SET     ID_REFERENCIA   = NVL(p_idReferencia, ID_REFERENCIA),
                NOMBRE          = NVL(p_nombre, NOMBRE),
                VALOR_EXT       = NVL(p_valorExt, VALOR_EXT),
                ID_TIPO_DATO    = NVL(p_idTipoDato, ID_TIPO_DATO),
                NIVEL           = NVL(p_nivel, NIVEL),
                ID_PADRE        = NVL(p_idPadre, ID_PADRE),
                ID_ESTADO       = NVL(p_idEstado, ID_ESTADO),
                FECHA_REG       = SYSDATE,
                USER_REG        = NVL(p_userReg, USER_REG)
        WHERE   ID_ITEM         = p_idItem
                AND ( 
                    DECODE(ID_REFERENCIA, NVL(p_idReferencia, ID_REFERENCIA), 0, 1) = 1 OR
                    DECODE(NOMBRE, NVL(p_nombre, NOMBRE), 0, 1) = 1 OR
                    DECODE(VALOR_EXT, NVL(p_valorExt, VALOR_EXT), 0, 1) = 1 OR
                    DECODE(ID_TIPO_DATO, NVL(p_idTipoDato, ID_TIPO_DATO), 0, 1) = 1 OR
                    DECODE(NIVEL, NVL(p_nivel, NIVEL), 0, 1) = 1 OR
                    DECODE(ID_PADRE, NVL(p_idPadre, ID_PADRE), 0, 1) = 1 OR
                    DECODE(ID_ESTADO, NVL(p_idEstado, ID_ESTADO), 0, 1) = 1 OR
                    DECODE(USER_REG, NVL(p_userReg, USER_REG), 0, 1) = 1
                );

        IF SQL%ROWCOUNT = 0 THEN
            v_message := CONST.MSG_NO_ROWS_AFFECTED;
        END IF;

        OPEN p_cursor FOR SELECT p_idItem AS "uid", CONST.MSG_UPDATE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN v_notNull THEN
            RAISE_APPLICATION_ERROR(-20006, 'Existen campos obligatorios sin valor.');
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT( 'p_idItem' VALUE p_idItem, 'p_idReferencia' VALUE p_idReferencia, 'p_nombre' VALUE p_nombre, 'p_valorExt' VALUE p_valorExt, 'p_idTipoDato' VALUE p_idTipoDato, 'p_nivel' VALUE p_nivel, 'p_idPadre' VALUE p_idPadre,
                                'p_idEstado' VALUE p_idEstado, 'p_userReg' VALUE p_userReg, 'ora-error' VALUE v_errorCode, 'ora-msg' VALUE v_errorMessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;
        WHEN v_fkParentMissing THEN
            IF SQLERRM LIKE '%PADRE%' THEN
                RAISE_APPLICATION_ERROR(-20006, 'El ID_PADRE no existe');
            ELSE
                RAISE_APPLICATION_ERROR(-20006, 'El ID_REFERENCIA no existe');
            END IF;
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT( 'p_idItem' VALUE p_idItem, 'p_idReferencia' VALUE p_idReferencia, 'p_nombre' VALUE p_nombre, 'p_valorExt' VALUE p_valorExt, 'p_idTipoDato' VALUE p_idTipoDato, 'p_nivel' VALUE p_nivel, 'p_idPadre' VALUE p_idPadre,
                                'p_idEstado' VALUE p_idEstado, 'p_userReg' VALUE p_userReg, 'ora-error' VALUE v_errorCode, 'ora-msg' VALUE v_errorMessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT( 'p_idItem' VALUE p_idItem, 'p_idReferencia' VALUE p_idReferencia, 'p_nombre' VALUE p_nombre, 'p_valorExt' VALUE p_valorExt, 'p_idTipoDato' VALUE p_idTipoDato, 'p_nivel' VALUE p_nivel, 'p_idPadre' VALUE p_idPadre,
                                'p_idEstado' VALUE p_idEstado, 'p_userReg' VALUE p_userReg, 'ora-error' VALUE v_errorCode, 'ora-msg' VALUE v_errorMessage, 'linea_err' VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE RETURNING CLOB )
            INTO v_data FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END UPDATE_REFERENCIAITEM;

    ----------------------------------------
    -- DELETE LOGICO
    ----------------------------------------
    PROCEDURE DELETE_LOGICO_REFERENCIAITEM (
        p_idItem                IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_userReg               IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_item', p_idItem, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        UPDATE  GRL_REFERENCIA_ITEM
        SET     ID_ESTADO = CONST.REF_ITEM_ESTADO_ELIMINADO
        WHERE   ID_ITEM = p_idItem
                AND ID_ESTADO <> CONST.REF_ITEM_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idItem AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idItem'          VALUE p_idItem,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END DELETE_LOGICO_REFERENCIAITEM;

    ----------------------------------------
    -- DELETE FISICO
    ----------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIAITEM (
        p_idItem                IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_userReg               IN GRL_REFERENCIA_ITEM.USER_REG%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_item', p_idItem, 'required|int'),
            VALIDATOR.RULE('user_reg', p_userReg, 'required|int')
        ));

        DELETE_LOGICO_REFERENCIAITEM(p_idItem, p_userReg, p_cursor);

        DELETE FROM GRL_REFERENCIA_ITEM
        WHERE ID_ITEM = p_idItem
        AND ID_ESTADO = CONST.REF_ITEM_ESTADO_ELIMINADO;

        OPEN p_cursor FOR SELECT p_idItem AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idItem'          VALUE p_idItem,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM DUAL;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END DELETE_FISICO_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT por ID
    ----------------------------------------
    PROCEDURE GETBYID_REFERENCIAITEM (
        p_idItem                IN GRL_REFERENCIA_ITEM.ID_ITEM%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_item', p_idItem, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT  ID_ITEM                                 AS "idItemReferenciaItem", 
                    ID_REFERENCIA                           AS "idReferenciaItem", 
                    NOMBRE                                  AS "nombreReferenciaItem", 
                    VALOR_EXT                               AS "valorExtReferenciaItem", 
                    ID_TIPO_DATO                            AS "idTipoDatoReferenciaItem", 
                    NIVEL                                   AS "nivelReferenciaItem", 
                    ID_PADRE                                AS "idPadreReferenciaItem", 
                    ID_ESTADO                               AS "idEstadoReferenciaItem",
                    TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferenciaItem",
                    USER_REG                                AS "userRegReferenciaItem"
            FROM    GRL_REFERENCIA_ITEM
            WHERE   ID_ITEM = p_idItem;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idItem'          VALUE p_idItem,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETBYID_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT por ID REF
    ----------------------------------------
    PROCEDURE GETBYIDREF_REFERENCIAITEM (
        p_idReferencia          IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT  ID_ITEM                                 AS "idItemReferenciaItem", 
                    ID_REFERENCIA                           AS "idReferenciaItem", 
                    NOMBRE                                  AS "nombreReferenciaItem", 
                    VALOR_EXT                               AS "valorExtReferenciaItem", 
                    ID_TIPO_DATO                            AS "idTipoDatoReferenciaItem", 
                    NIVEL                                   AS "nivelReferenciaItem", 
                    ID_PADRE                                AS "idPadreReferenciaItem", 
                    ID_ESTADO                               AS "idEstadoReferenciaItem",
                    TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferenciaItem",
                    USER_REG                                AS "userRegReferenciaItem"
            FROM    GRL_REFERENCIA_ITEM
            WHERE   ID_REFERENCIA = p_idReferencia;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETBYIDREF_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT por ID PADRE
    ----------------------------------------
    PROCEDURE GETBYIDPADRE_REFERENCIAITEM (
        p_idPadre               IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_padre', p_idPadre, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT      ID_ITEM                                 AS "idItemReferenciaItem", 
                        ID_REFERENCIA                           AS "idReferenciaItem", 
                        NOMBRE                                  AS "nombreReferenciaItem", 
                        VALOR_EXT                               AS "valorExtReferenciaItem", 
                        ID_TIPO_DATO                            AS "idTipoDatoReferenciaItem", 
                        NIVEL                                   AS "nivelReferenciaItem", 
                        ID_PADRE                                AS "idPadreReferenciaItem", 
                        ID_ESTADO                               AS "idEstadoReferenciaItem",
                        TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferenciaItem",
                        USER_REG                                AS "userRegReferenciaItem"
            FROM        GRL_REFERENCIA_ITEM
            WHERE       ID_PADRE = p_idPadre
            ORDER BY    ID_ITEM;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idPadre'         VALUE p_idPadre,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETBYIDPADRE_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT por NIVEL
    ----------------------------------------
    PROCEDURE GETBYNIVEL_REFERENCIAITEM (
        p_idReferencia          IN GRL_REFERENCIA_ITEM.ID_REFERENCIA%TYPE,
        p_nivel                 IN GRL_REFERENCIA_ITEM.NIVEL%TYPE,
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_referencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('nivel', p_nivel, 'required|int')
        ));

        OPEN p_cursor FOR
            SELECT      a.ID_REFERENCIA     AS "idReferencia", 
                        a.NOMBRE            AS "nombreReferencia", 
                        a.DESCRIPCION       AS "descripcionReferencia", 
                        a.ID_TIPO           AS "idTipoReferencia", 
                        a.ID_CLASE          AS "idClaseReferencia", 
                        a.ID_ESTADO         AS "idEstadoReferencia", 
                        b.ID_ITEM           AS "idItemReferenciaItem", 
                        b.NOMBRE            AS "nombreReferenciaItem", 
                        b.NIVEL             AS "nivelReferenciaItem",
                        b.ID_PADRE          AS "idPadreReferenciaItem",
                        b.ID_ESTADO         AS "idEstadoReferenciaItem", 
                        b.ID_TIPO_DATO      AS "idTipoDatoReferenciaItem",
                        b.VALOR_EXT         AS "valorExtReferenciaItem"
            FROM        GRL_REFERENCIA a, GRL_REFERENCIA_ITEM b
            WHERE       a.ID_REFERENCIA = b.ID_REFERENCIA
                        AND a.ID_REFERENCIA = p_idReferencia
                        AND b.NIVEL = p_nivel
            ORDER BY    a.ID_REFERENCIA ASC;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'p_nivel'           VALUE p_nivel,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETBYNIVEL_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT todos
    ----------------------------------------
    PROCEDURE GETALL_REFERENCIAITEM (
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        OPEN p_cursor FOR
            SELECT      ID_ITEM                                 AS "idItemReferenciaItem", 
                        ID_REFERENCIA                           AS "idReferenciaItem", 
                        NOMBRE                                  AS "nombreReferenciaItem", 
                        VALOR_EXT                               AS "valorExtReferenciaItem", 
                        ID_TIPO_DATO                            AS "idTipoDatoReferenciaItem", 
                        NIVEL                                   AS "nivelReferenciaItem", 
                        ID_PADRE                                AS "idPadreReferenciaItem", 
                        ID_ESTADO                               AS "idEstadoReferenciaItem",
                        TO_CHAR(FECHA_REG, 'DD-MM-YYYY')        AS "fechaRegReferenciaItem",
                        USER_REG                                AS "userRegReferenciaItem"
            FROM        GRL_REFERENCIA_ITEM
            ORDER BY    ID_ITEM;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETALL_REFERENCIAITEM;

    ----------------------------------------
    -- SELECT todos Estados
    ----------------------------------------
    PROCEDURE GETALLESTADOS_REFERENCIAITEM (
        p_cursor                OUT SYS_REFCURSOR
    ) IS
        v_data                  CLOB; -- Variable para almacenar un JSON
        v_logId                 NUMBER;
        v_errorCode             NUMBER;  
        v_errorMessage          VARCHAR2(4000);
    BEGIN
        OPEN p_cursor FOR
            SELECT ID_ESTADO_ITEM, ESTADO_ITEM FROM GENERALIDADES.GRL_ESTADO_ITEM_VW;

    EXCEPTION
        WHEN OTHERS THEN
            v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            SELECT JSON_OBJECT(
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_idApp, CONST.LOG_ERROR, v_data, v_logId);
            OPEN p_cursor FOR SELECT v_logId AS "uid", CONST.MSG_ERROR_INESPERADO AS "message", 0 AS "state" FROM DUAL;

    END GETALLESTADOS_REFERENCIAITEM;

    ---------------------------------------------------------------------------
    -- Obtiene nombre de un codigo especifico de "referencia item" | 05-03-2026
    ---------------------------------------------------------------------------
    FUNCTION GETNOMBRE_REFERENCIAITEM (
        p_idItem                IN GRL_REFERENCIA_ITEM.id_item%TYPE
    ) RETURN VARCHAR2 IS
        v_nombre                GRL_REFERENCIA_ITEM.NOMBRE%type;
    BEGIN
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('id_item', p_idItem, 'required|int')
        ));

        SELECT NOMBRE INTO v_nombre FROM GRL_REFERENCIA_ITEM WHERE ID_ITEM = p_idItem;
        RETURN v_nombre;

    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;    
    END;

END PKG_REFERENCIA_ITEM;


/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_REFERENCIA_ITEM" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package Body PKG_REFERENCIA_ROL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_REFERENCIA_ROL" AS 
	-------------------------------------------------------------------------- 
	-- VARIABLES GLOBALES DEL PACKAGE 
	-------------------------------------------------------------------------- 
	v_idApp					NUMBER := 0; -- 'CONST.[CONSTANTE ID_APP];' -- ID del package 

	-------------------------------------------------------------------------- 
	-- INSERT 
	-------------------------------------------------------------------------- 
	PROCEDURE INSERT_REFERENCIA_ROL( 
		p_idReferencia   			IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE ,
		p_idRol          			IN GRL_REFERENCIA_ROL.ID_ROL%TYPE , 
		p_userReg        			IN GRL_REFERENCIA_ROL.USER_REG%TYPE , 
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_idReferencia				GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE;
		v_errorCode					NUMBER;
		v_errorMessage				VARCHAR2(512);
	BEGIN
		--Aplicar validaciones a los campos antes de realizar el insert 
		VALIDATOR.VALIDATE(T_RULES(
 			VALIDATOR.RULE('p_idReferencia', p_idReferencia, 'required|int'), 
			VALIDATOR.RULE('p_idRol', p_idRol, 'required|int'),  
			VALIDATOR.RULE('p_userReg', p_userReg, 'required|int')
 		));

		INSERT INTO GRL_REFERENCIA_ROL(ID_REFERENCIA, ID_ROL, FECHA_REG, USER_REG) 
		VALUES(p_idReferencia, p_idRol, SYSDATE, p_userReg);

		OPEN p_cursor FOR SELECT p_idReferencia||'-'||p_idRol AS "uid", CONST.MSG_INSERT_OK AS "message", 1 AS "state" FROM DUAL;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
					'p_idRol'           VALUE p_idRol,
					'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END INSERT_REFERENCIA_ROL; 

	-------------------------------------------------------------------------- 
	-- DELETE LOGICO 
	-------------------------------------------------------------------------- 
	PROCEDURE DELETE_LOGICO_REFERENCIA_ROL(
		p_idReferencia   			IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_idRol          			IN GRL_REFERENCIA_ROL.ID_ROL%TYPE, 
        p_userReg        			IN GRL_REFERENCIA_ROL.USER_REG%TYPE ,
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
		VALIDATOR.VALIDATE(T_RULES(
 			VALIDATOR.RULE('p_idReferencia', p_idReferencia, 'required|int'), 
            VALIDATOR.RULE('p_idRol', p_idRol, 'required|int'), 
			VALIDATOR.RULE('p_userReg', p_userReg, 'required|int')
 		));

        /*UPDATE GRL_REFERENCIA_ROL
        SET FECHA_REG = SYSDATE,
        USER_REG = p_userReg
        WHERE ID_REFERENCIA = p_idReferencia
        AND ID_ROL = p_idRol
        */
		OPEN p_cursor FOR SELECT p_idReferencia||'-'||p_idRol AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'id_referencia'     VALUE p_idReferencia,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END DELETE_LOGICO_REFERENCIA_ROL; 

	-------------------------------------------------------------------------- 
	-- DELETE FISICO 
	-------------------------------------------------------------------------- 
	PROCEDURE DELETE_FISICO_REFERENCIA_ROL(
		p_idReferencia   			IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
        p_idRol          			IN GRL_REFERENCIA_ROL.ID_ROL%TYPE ,
        p_userReg        			IN GRL_REFERENCIA_ROL.USER_REG%TYPE ,
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
		VALIDATOR.VALIDATE(T_RULES(
 			VALIDATOR.RULE('p_idReferencia', p_idReferencia, 'required|int'),
            VALIDATOR.RULE('p_idRol', p_idRol, 'required|int'),
			VALIDATOR.RULE('p_userReg', p_userReg, 'required|int')
 		));

		--DELETE_LOGICO_GRL_REFERENCIA_ROL(p_idReferencia, p_idRol, p_userReg, p_cursor);

		DELETE FROM GRL_REFERENCIA_ROL 
		WHERE ID_REFERENCIA = p_idReferencia
        AND ID_ROL = p_idRol; 

		OPEN p_cursor FOR SELECT p_idReferencia AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'id_referencia'     VALUE p_idReferencia,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END DELETE_FISICO_REFERENCIA_ROL; 

	-------------------------------------------------------------------------- 
	-- SELECT BY ID 
	-------------------------------------------------------------------------- 
	PROCEDURE GETBYID_REFERENCIA_ROL(
		p_idReferencia   			IN GRL_REFERENCIA_ROL.ID_REFERENCIA%TYPE,
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
		OPEN p_cursor FOR 
			SELECT 	ID_REFERENCIA   AS "idReferenciaRol",
					ID_ROL          AS "idRolReferenciaRol",
					FECHA_REG       AS "fechaRegReferenciaRol",
					USER_REG        AS "userRegReferenciaRol" 
 			FROM 	GRL_REFERENCIA_ROL 
			WHERE 	ID_REFERENCIA = p_idReferencia;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'id_referencia'     VALUE p_idReferencia,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END GETBYID_REFERENCIA_ROL; 

    -------------------------------------------------------------------------- 
	-- SELECT BY ID ROL
	-------------------------------------------------------------------------- 
	PROCEDURE GETBYIDROL_REFERENCIA_ROL(
		p_idRol                     IN GRL_REFERENCIA_ROL.ID_ROL%TYPE,
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
		OPEN p_cursor FOR 
			SELECT 	ID_REFERENCIA   AS "idReferenciaRol",
					ID_ROL          AS "idRolReferenciaRol",
					FECHA_REG       AS "fechaRegReferenciaRol",
					USER_REG        AS "userRegReferenciaRol" 
 			FROM 	GRL_REFERENCIA_ROL 
			WHERE 	ID_ROL = p_idRol;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'p_idRol'           VALUE p_idRol,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END GETBYIDROL_REFERENCIA_ROL;

	-------------------------------------------------------------------------- 
	-- SELECT ALL 
	-------------------------------------------------------------------------- 
	PROCEDURE GETALL_REFERENCIA_ROL(
		p_cursor         			OUT SYS_REFCURSOR  
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
		OPEN p_cursor FOR 
			SELECT 	ID_REFERENCIA   AS "idReferenciaRol",
					ID_ROL          AS "idRolReferenciaRol",
					FECHA_REG       AS "fechaRegReferenciaRol",
					USER_REG        AS "userRegReferenciaRol" 
 			FROM 	GRL_REFERENCIA_ROL 
			ORDER BY ID_REFERENCIA;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_idApp,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END GETALL_REFERENCIA_ROL; 

END PKG_REFERENCIA_ROL;


/
--------------------------------------------------------
--  DDL for Package Body PKG_REFERENCIA_SISTEMA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_REFERENCIA_SISTEMA" IS
    --------------------------------------------------------------------------
    -- VARIABLES GLOBALES
    --------------------------------------------------------------------------
  	v_cod_app      NUMBER := 10;     -- ID del package

    --------------------------------------------------------------------------------------------------------
    -- Inserta un nuevo registro en la tabla GRL_referencia_sistema, relaci�n entre sistema y preferencia.
    --------------------------------------------------------------------------------------------------------
    PROCEDURE INSERT_REFERENCIA_SISTEMA (
		p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    ) IS
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;
		v_errorMessage				VARCHAR2(512);
    BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
	    VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('p_idReferencia',p_idReferencia,'required|int|min=1'),
        	VALIDATOR.RULE('p_idSistema',p_idSistema,'required|int|min=1'),
        	VALIDATOR.RULE('p_userReg',p_userReg,'required|int')
    	));

        INSERT INTO GRL_REFERENCIA_SISTEMA (ID_REFERENCIA ,ID_SISTEMA, FECHA_REG, USER_REG)
        VALUES (p_idReferencia ,p_idSistema, SYSDATE, p_userReg);

     	OPEN p_cursor FOR
	        SELECT  p_idReferencia||'-'||p_idSistema AS "uid",
	    			CONST.MSG_DELETE_OK AS "message",
	    			1 AS "state"
	    	FROM dual;
    EXCEPTION
        WHEN OTHERS THEN
             v_errorCode := SQLCODE;
             v_errorMessage := SQLERRM;
             --- Se pasan los parametros a JSON
             SELECT JSON_OBJECT(
                            'id_referencia'         VALUE p_idReferencia,
                        	'id_sistema'            VALUE p_idSistema,
                            'p_userReg'             VALUE p_userReg,
                            'ora-error'             VALUE v_errorCode,
                            'ora-msg'               VALUE v_errorMessage,
                            'linea_err'             VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB
                    )
             INTO v_data
             FROM dual;
             --- Se registra la excepti�m
             PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR,v_data,v_logId);
        	 OPEN p_cursor FOR 
    							SELECT 	v_logId  AS "uid", 
    									UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message", 
    									0 "state"  
   								FROM DUAL;
    END INSERT_REFERENCIA_SISTEMA;

    -------------------------------------------------------------------------- 
	-- DELETE LOGICO 
	-------------------------------------------------------------------------- 
	PROCEDURE DELETE_LOGICO_REFERENCIA_SISTEMA (
		p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
	) IS 
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
	BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
		VALIDATOR.VALIDATE(T_RULES(
 			VALIDATOR.RULE('p_idReferencia',p_idReferencia,'required|int'),
        	VALIDATOR.RULE('p_idSistema',p_idSistema,'required|int'),
            VALIDATOR.RULE('p_userReg',p_userReg,'required|int')
 		));

        /*UPDATE GRL_REFERENCIA_SISTEMA
        SET FECHA_REG = SYSDATE,
        USER_REG = p_userReg
        WHERE ID_REFERENCIA = p_idReferencia
        AND ID_SISTEMA = p_idSistema
        */
		OPEN p_cursor FOR SELECT p_idReferencia||'-'||p_idSistema AS "uid", CONST.MSG_DELETE_OK AS "message", 1 AS "state" FROM DUAL;

	EXCEPTION WHEN OTHERS THEN 
		v_errorCode := SQLCODE;
		v_errorMessage := SQLERRM;
		SELECT JSON_OBJECT(
                    'p_idReferencia'    VALUE p_idReferencia,
                    'p_idSistema'       VALUE p_idSistema,
                    'p_userReg'         VALUE p_userReg,
                    'ora-error'         VALUE v_errorCode,
                    'ora-msg'           VALUE v_errorMessage,
                    'linea_err'         VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                RETURNING CLOB
            )
        INTO v_data FROM DUAL;

		GENERALIDADES.PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR, v_data, v_logId);
		OPEN p_cursor FOR SELECT v_logId AS "uid", UTILIDADES.HANDLE_EXCEPTION(v_errorcode,v_errormessage) AS "message", 0 AS "state" FROM DUAL;

	END DELETE_LOGICO_REFERENCIA_SISTEMA;

    --------------------------------------------------------------------------------------------------------
    -- Actualiza un registro en la tabla GRL_PARAMETRO_ROL, relaci�n entre parametro y rol de usuario.
    --------------------------------------------------------------------------------------------------------
    PROCEDURE DELETE_FISICO_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_userReg                   IN GRL_REFERENCIA_SISTEMA.USER_REG%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    ) IS
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
    BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
	    VALIDATOR.VALIDATE(T_RULES(
        	VALIDATOR.RULE('p_idReferencia',p_idReferencia,'required|int'),
        	VALIDATOR.RULE('p_idSistema',p_idSistema,'required|int'),
            VALIDATOR.RULE('p_userReg',p_userReg,'required|int')
    	));

        --DELETE_LOGICO_REFERENCIA_SISTEMA(p_idReferencia, p_idSistema, p_userReg, p_cursor);

        DELETE FROM GRL_REFERENCIA_SISTEMA 
        WHERE ID_REFERENCIA = p_idReferencia
   		AND ID_SISTEMA = p_idSistema;

        OPEN p_cursor FOR
        SELECT  p_idReferencia||'-'||p_idSistema AS "uid",
    			CONST.MSG_DELETE_OK AS "message",
    			1 AS   "state"
    	FROM dual;

    EXCEPTION
        WHEN OTHERS THEN
             v_errorCode := SQLCODE;
             v_errorMessage := SQLERRM;
             SELECT JSON_OBJECT(
                            'p_idReferencia'        VALUE p_idReferencia,
                        	'p_idSistema'           VALUE p_idSistema,
                            'p_userReg'             VALUE p_userReg,
                            'ora-error'           	VALUE v_errorCode,
                            'ora-msg'             	VALUE v_errorMessage,
                            'linea_err'           	VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB
                    )
             INTO v_data
             FROM dual;
        PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR,v_data,v_logId);
 		OPEN p_cursor FOR 
    							SELECT 	v_logId  AS "uid", 
    									UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message", 
    									0 "state"  
   								FROM DUAL;

    END DELETE_FISICO_REFERENCIA_SISTEMA;

    ---------------------------------------------------------------------------------------
    -- Entrega la lista de referencia que tiene asignado el sistema dado su ID
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALLBYSISTEMA_REFERENCIA_SISTEMA (
        p_idSistema                 IN GRL_REFERENCIA_SISTEMA.ID_SISTEMA%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    ) IS
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
    BEGIN
        --Aplicar validaciones a los campos antes de realizar el insert 
	    VALIDATOR.VALIDATE(T_RULES(
        	VALIDATOR.RULE('p_idSistema',p_idSistema,'required|int')
    	));

        OPEN p_cursor FOR
        SELECT 	ID_REFERENCIA                   AS "idReferenciaSistema",
                ID_SISTEMA                      AS "idSistemaReferenciaSistema",
        		TO_CHAR(FECHA_REG,'DD/MM/YYYY') AS "fechaRegReferenciaSistema",
                USER_REG                        AS "userRegReferenciaSistema"
        FROM 	GRL_REFERENCIA_SISTEMA
        WHERE 	ID_SISTEMA = p_idSistema;

    EXCEPTION
        WHEN OTHERS THEN
             v_errorCode := SQLCODE;
             v_errorMessage := SQLERRM;
             SELECT JSON_OBJECT(
                        	'id_sistema'          VALUE p_idSistema,
                            'ora-error'           VALUE v_errorCode,
                            'ora-msg'             VALUE v_errorMessage,
                            'linea_err'           VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB
                    )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR,v_data,v_logId);
	 		OPEN p_cursor FOR 
    							SELECT 	v_logId  AS "uid", 
    									UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message", 
    									0 "state"  
   								FROM DUAL;

    END GETALLBYSISTEMA_REFERENCIA_SISTEMA;

	---------------------------------------------------------------------------------------
    -- Entrega la lista de sistemas que tiene asignado una referencia dado su ID
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALLBYREFERENCIA_REFERENCIA_SISTEMA (
        p_idReferencia              IN GRL_REFERENCIA_SISTEMA.ID_REFERENCIA%TYPE,
        p_cursor                    OUT SYS_REFCURSOR
    ) IS
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
    BEGIN
	    --Aplicar validaciones a los campos antes de realizar el insert 
	    VALIDATOR.VALIDATE(T_RULES(
        	VALIDATOR.RULE('p_idReferencia',p_idReferencia,'required|int')
    	));

        OPEN p_cursor FOR
        SELECT 	ID_REFERENCIA                   AS "idReferenciaSistema",
                ID_SISTEMA                      AS "idSistemaReferenciaSistema",
        		TO_CHAR(FECHA_REG,'DD/MM/YYYY') AS "fechaRegReferenciaSistema",
                USER_REG                        AS "userRegReferenciaSistema"
        FROM 	GRL_REFERENCIA_SISTEMA
        WHERE 	ID_REFERENCIA = p_idReferencia;

    EXCEPTION
        WHEN OTHERS THEN
             v_errorCode := SQLCODE;
             v_errorMessage := SQLERRM;
             SELECT JSON_OBJECT(
                        	'id_referencia'       VALUE p_idReferencia,
                            'ora-error'           VALUE v_errorCode,
                            'ora-msg'             VALUE v_errorMessage,
                            'linea_err'           VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB
                    )
             INTO v_data
             FROM dual;
    		PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR,v_data,v_logId);
	 		OPEN p_cursor FOR 
    							SELECT 	v_logId  AS "uid",
    									UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message", 
    									0 "state"  
   								FROM DUAL;

    END GETALLBYREFERENCIA_REFERENCIA_SISTEMA;

    ---------------------------------------------------------------------------------------
    -- Entrega toda la informacion de la tabla GRL_REFERENCIA_SISTEMA
    ---------------------------------------------------------------------------------------
    PROCEDURE GETALL_REFERENCIA_SISTEMA (
        p_cursor                    OUT SYS_REFCURSOR
    ) IS
        v_data					    CLOB; -- Variable para almacenar un JSON 
        v_logId					    NUMBER;
		v_errorCode					NUMBER;  
		v_errorMessage				VARCHAR2(512);
    BEGIN
        OPEN p_cursor FOR
        SELECT 	ID_REFERENCIA                   AS "idReferenciaSistema",
                ID_SISTEMA                      AS "idSistemaReferenciaSistema",
        		TO_CHAR(FECHA_REG,'DD/MM/YYYY') AS "fechaRegReferenciaSistema",
                USER_REG                        AS "userRegReferenciaSistema"
        FROM 	GRL_REFERENCIA_SISTEMA;

    EXCEPTION
        WHEN OTHERS THEN
             v_errorCode := SQLCODE;
             v_errorMessage := SQLERRM;
             SELECT JSON_OBJECT(
                        	'ora-error'           VALUE v_errorCode,
                            'ora-msg'             VALUE v_errorMessage,
                            'linea_err'           VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        RETURNING CLOB
                    )
            INTO v_data
            FROM dual;
            PKG_LOG.REGISTRA_LOG(v_cod_app,CONST.LOG_ERROR,v_data,v_logId);
	 		OPEN p_cursor FOR 
    							SELECT 	v_logId  AS "uid", 
    									UTILIDADES.HANDLE_EXCEPTION(v_errorCode,v_errorMessage) AS "message", 
    									0 "state"  
   								FROM DUAL;
    END GETALL_REFERENCIA_SISTEMA;

END PKG_REFERENCIA_SISTEMA;

/
--------------------------------------------------------
--  DDL for Package Body PKG_UTILIDADES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_UTILIDADES" AS
    PROCEDURE VALIDATE_PERSONA (
        p_idPersona     IN GENERALIDADES.GRL_PERSONA.ID_PERSONA%TYPE
    ) AS
        v_check         PLS_INTEGER;
    BEGIN
        SELECT 1
          INTO v_check
          FROM GENERALIDADES.GRL_PERSONA
         WHERE ID_PERSONA = p_idPersona
           AND NVL(FALLECIDO, 'N') = 'N';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(PKG_GRL_CONFIG.ERROR_NEGOCIO, 'La persona no existe.');
    END VALIDATE_PERSONA;

 PROCEDURE VALIDATE_ITEM(
    p_idPadre  IN GRL_REFERENCIA_ITEM.ID_PADRE%TYPE,
    p_idItem   IN NUMBER
    ) AS
        v_check      PLS_INTEGER;
        --v_disponibles VARCHAR2(4000);
    BEGIN
/*       
PROBANDO PROBANDO
SELECT 1
          INTO v_check
          FROM GRL_REFERENCIA_ITEM
         WHERE ID_PADRE = p_idPadre
           AND ID_ITEM  = p_idItem
           AND ID_ESTADO = CONST.REF_ITEM_ESTADO_ACTIVO;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT LISTAGG(ID_ITEM, ', ') WITHIN GROUP (ORDER BY ID_ITEM)
          INTO v_disponibles
          FROM GRL_REFERENCIA_ITEM
         WHERE ID_PADRE = p_idPadre
         AND ID_ESTADO = CONST.REF_ITEM_ESTADO_ACTIVO;

        RAISE_APPLICATION_ERROR(
            PKG_GRL_CONFIG.ERROR_NEGOCIO,
            'Item no encontrado. ID enviado: ' || p_idItem ||
            '. Items disponibles para padre ' || p_idPadre || ': ' ||
            COALESCE(v_disponibles, 'ninguno')
        );*/


----- SI FUNKA BORRAR ARRIBA

    /*  
        query para ver si es q un item pertenece a una referencia
        en el caso de que sea jerarjica, verifico en base a su padre 
        X EJ: si quiero validar que rancagua pertenece a la 6ta regi�n, valido contra eso y no contra todas las regiones del pais (jerarjica)
        si quiero validar que un pais sea vigente, valido contra todos los paises del mundo (lineal)
     */
    
    SELECT 1
          INTO v_check
          FROM GRL_REFERENCIA_ITEM
         WHERE ((DECODE((SELECT R.ID_CLASE FROM GRL_REFERENCIA R
                   INNER JOIN GRL_REFERENCIA_ITEM RI
                   ON R.ID_REFERENCIA = RI.ID_REFERENCIA
                   WHERE RI.ID_ITEM = p_idItem
                   AND RI.ID_ESTADO = CONST.REF_ITEM_ESTADO_ACTIVO), CONST.REF_ITEM_ESTADO_LINEAL, 1, 0) = 1 AND ID_REFERENCIA = p_idPadre) -- si es lineal, cruzo con el campo id_referencia
            OR (DECODE((SELECT R.ID_CLASE FROM GRL_REFERENCIA R
                   INNER JOIN GRL_REFERENCIA_ITEM RI
                   ON R.ID_REFERENCIA = RI.ID_REFERENCIA
                   WHERE RI.ID_ITEM = p_idItem
                   AND RI.ID_ESTADO = CONST.REF_ITEM_ESTADO_ACTIVO), CONST.REF_ITEM_ESTADO_JERARQUICA, 1, 0) = 1 AND ID_PADRE = p_idPadre)) -- si es jerarjica, cruzo con el campo id_padre
           AND ID_ITEM  = p_idItem
           AND ID_ESTADO = CONST.REF_ITEM_ESTADO_ACTIVO;
           
    EXCEPTION
        WHEN NO_DATA_FOUND THEN           
               RAISE_APPLICATION_ERROR(PKG_GRL_CONFIG.ERROR_NEGOCIO, 'Item no encontrado');
    END VALIDATE_ITEM;

    FUNCTION HANDLE_EXCEPTION(
        p_errorCode     IN NUMBER,
        p_errorMessage  IN VARCHAR2
    ) RETURN VARCHAR2 IS
    v_mensaje varchar2(200);
    BEGIN
        IF p_errorCode >= PKG_GRL_CONFIG.ERROR_RANGO_INI AND p_errorCode <= PKG_GRL_CONFIG.ERROR_RANGO_FIN THEN
            --RAISE_APPLICATION_ERROR(p_errorCode, p_errorMessage);
            v_mensaje := LTRIM(SUBSTR(
            SUBSTR(p_errorMessage, 1, INSTR(p_errorMessage || CHR(10), CHR(10)) - 1),
            INSTR(p_errorMessage, ':') + 1
        ));
        
            return v_mensaje;
        ELSE
            --RAISE_APPLICATION_ERROR(PKG_GRL_CONFIG.ERROR_NEGOCIO, PKG_GRL_CONFIG.MSG_ERROR_INESPERADO);
            return PKG_GRL_CONFIG.MSG_ERROR_INESPERADO;
        END IF;
    END HANDLE_EXCEPTION;

    FUNCTION TO_FLOAT(p_value IN VARCHAR2) return NUMBER IS
        BEGIN
            RETURN TO_NUMBER(REPLACE(p_value,'.',',') DEFAULT NULL ON CONVERSION ERROR);
    END TO_FLOAT;



    FUNCTION creaReferencias(p_nombre varchar2, p_descripcion varchar2, p_items varchar2, p_rut_user number, p_nombre_vista varchar2 default null) return tt_referencias pipelined is


        cursor cur_items is
            select regexp_substr(p_items,'[^,]+', 1, level) item
            from dual
            connect by regexp_substr(p_items, '[^,]+', 1, level) is not null;

        cursor cur_items_registrados(p_id_referencia number) is
            select id_item,id_referencia,nombre,valor_ext,id_tipo_dato,nivel,id_padre,id_estado,fecha_reg,user_reg
            from grl_referencia_item
            where id_referencia = p_id_referencia;


        v_nombre            grl_referencia.nombre%type              := trim(p_nombre);
        v_descripcion       grl_referencia.descripcion%type;
        v_user_reg          grl_persona.id_persona%type;                    -- es un rut que se obtiene por query
        v_id_referencia     grl_referencia.id_referencia%type;              -- es una secuencia
        v_id_tipo           grl_referencia.id_tipo%type             := 100; -- [100= SISTEMA]  [110=USUARIO]
        v_id_clase          grl_referencia.id_clase%type            := 120; -- [120= LINEAL]   [121=JERAQUICA]
        v_id_estado         grl_referencia.id_estado%type           := 123; -- [122= INACTIVO]   [123= ACTIVO]  [124=ELIMINADO]
        
        v_id_item           grl_referencia_item.id_item%type;               -- es una secuencia    
        v_id_tipo_dato_item grl_referencia_item.id_tipo_dato%type   := 131; -- [75: LISTA]  [131: CHAR]   [132:INT]    [133: NUMBER]    [134: DATE]  
        
        v_nivel_item        grl_referencia_item.nivel%type          := 1;   -- por ahora fijo en 1   
        v_id_estado_item    grl_referencia_item.id_estado%type      := 125; -- [125: ACTIVO]  [126:INACTIVO]   [127: ELIMINADO]
        
        v_existe            number;
        v_script_ref        varchar2(32000);
        v_script_item       varchar2(32000);
        v_vistas            varchar2(32000);
        l_fila              tr_referencias;
            
        v_cursor_ref        SYS_REFCURSOR;
        v_cursor_item       SYS_REFCURSOR;
        v_msg               varchar2(2000);
        v_state             number;
        v_obs               varchar2(1000);
        v_error             varchar2(1000);
        
        PRAGMA AUTONOMOUS_TRANSACTION;
        
    BEGIN

        select count(1)
        into v_existe
        from grl_referencia
        where lower(nombre) = lower(v_nombre);
        
        
        if v_existe > 0 then --ya estaba creado 
        
            dbms_output.put_line('WARNING: ya existe esta referencia ['||v_nombre||']');
        
            select id_referencia
            into v_id_referencia
            from grl_referencia
            where lower(nombre) = lower(v_nombre);
        
            v_obs :=  'Ya estaba creada esta referencia';
            
        else -- no se ha creado aun
        
            if p_items is null then
            
                dbms_output.put_line('Error: Se debe indicar al menos un items para ingresar');
                v_error := 'Error: Se debe indicar al menos un items para ingresar';
                return;
                
            end if;        
        
            
            begin
                select id_persona
                into v_user_reg
                from grl_persona
                where substr(identificador,1,instr(identificador,'-')-1) = p_rut_user; 
            
            exception when others then
             
                v_user_reg := null;
                dbms_output.put_line('ERROR: No se encuentra registro para el rut '||p_rut_user);
                v_error := 'ERROR: No se encuentra registro para el rut '||p_rut_user;
                return;
                
            end;
            
            pkg_referencia.insert_referencia(p_nombre,p_descripcion,v_id_tipo,v_id_clase,v_id_estado,v_user_reg,v_cursor_ref);                        
            
            loop
            fetch v_cursor_ref into v_id_referencia,v_msg,v_state;
            exit when v_cursor_ref%notfound;        
            end loop;
            close v_cursor_ref;
            
            
            if v_state <> 0 then -- si sale todo bien, seguimos
                                    
                for i in cur_items loop
                    
                    v_vistas := null;
                    pkg_referencia_item.insert_referenciaitem(v_id_referencia,trim(i.item),null,v_id_tipo_dato_item,v_nivel_item,null,v_id_estado_item,v_user_reg,v_cursor_item);
                    
                    commit;           
                    
                    loop
                    fetch v_cursor_item into v_id_item,v_msg,v_state;
                    exit when v_cursor_item%notfound;        
                    end loop;
                    close v_cursor_item;          
                    
                    if v_state = 0 then
                    
                        dbms_output.put_line('ERROR: No se pudo ingresa el item ['||trim(i.item)||']');
                    
                    end if;      
                
                end loop;                        
            
            end if;
                
        end if;
        
        
        --ARMAMOS LA TABLA
        
        if v_id_referencia > 0 then
        
            
            select nombre,descripcion,id_tipo,id_clase,id_estado,user_reg
            into v_nombre,v_descripcion,v_id_tipo,v_id_clase,v_id_estado,v_user_reg
            from grl_referencia
            where id_referencia=v_id_referencia;
                       
            v_script_ref := 'INSERT INTO grl_referencia(id_referencia,nombre,descripcion,id_tipo,id_clase,id_estado,fecha_reg,user_reg)
                                 VALUES ('||v_id_referencia||','''||v_nombre||''','''||v_descripcion||''','||v_id_tipo||','||v_id_clase||','||v_id_estado||',SYSDATE,'||v_user_reg||');';
            
            if p_nombre_vista is not null then
                                   
                v_vistas := 'CREATE OR REPLACE FORCE VIEW '||upper(p_nombre_vista)||'(codigo,nombre) AS
                             SELECT c.id_item codigo, c.nombre nombre
                             FROM generalidades.grl_referencia_item c
                             WHERE c.id_estado = '||v_id_estado_item||' AND c.id_referencia = '||v_id_referencia||';';
                            
            end if;        
            
            for r in cur_items_registrados(v_id_referencia) loop                        
                
                v_script_item := 'INSERT INTO grl_referencia_item(id_item,id_referencia,nombre,id_tipo_dato,nivel,id_estado,fecha_reg,user_reg)
                                  VALUES('||r.id_item||','||v_id_referencia||','''||r.nombre||''','||r.id_tipo_dato||','||r.nivel||','||r.id_estado||',SYSDATE,'||nvl(to_char(r.user_reg),'NULL')||');'; 
                                                                                                
                l_fila.id_referencia        := v_id_referencia;
                l_fila.id_item              := r.id_item;
                l_fila.nombre_item          := r.nombre;
                l_fila.script_insert_ref    := v_script_ref;           
                l_fila.script_insert_item   := v_script_item;
                l_fila.script_vista         := v_vistas;                      
                l_fila.observaciones        := v_obs;
                
                pipe row ( l_fila );
                
                v_script_ref := null;
                v_vistas     := null;
                
            end loop;            
        
        end if;
        
        return;
        
    EXCEPTION WHEN OTHERS THEN
        
        l_fila.id_referencia := null;
        l_fila.id_item       := null;
        l_fila.nombre_item   := null;
        l_fila.script_insert_ref := 'ERROR:'||sqlerrm;           
        l_fila.script_vista  := null;
                        
        pipe row ( l_fila );

        dbms_output.put_line('ERROR GENERAL: '||sqlerrm);    
        
        return;
        
    END;
    
    /* =====================================================================
        FUNCTION : BUILD_ERROR_CURSOR
        Centraliza el manejo de errores que se repetia identico en cada
        procedure del proyecto: captura SQLCODE/SQLERRM, arma el JSON de
        contexto + backtrace, registra el log, y devuelve el cursor de
        error listo para abrir.

        NOTA: CONST es sinonimo de PKG_GRL_CONFIG, por eso aqui se usa
        CONST.LOG_ERROR (ya confirmado, es el mismo que se usaba en
        PKG_SGR_ROL_USUARIO) en vez de PKG_GRL_CONFIG.LOG_ERROR.
    =======================================================================*/
    FUNCTION BUILD_ERROR_CURSOR(
        p_idApp    IN NUMBER,
        p_contexto IN CLOB
    ) RETURN SYS_REFCURSOR IS
        v_errorCode    NUMBER         := SQLCODE;
        v_errorMessage VARCHAR2(512)  := SQLERRM;
        v_idLog        NUMBER;
        v_data         CLOB;
        v_cursor       SYS_REFCURSOR;
    BEGIN
        SELECT JSON_OBJECT(
            'ora_code'   VALUE v_errorCode,
            'ora_msg'    VALUE v_errorMessage,
            'contexto'   VALUE p_contexto FORMAT JSON,
            'backtrace'  VALUE DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
            RETURNING CLOB)
        INTO v_data
        FROM DUAL;

        PKG_LOG.REGISTRA_LOG(p_idApp, CONST.LOG_ERROR, v_data, v_idLog);

        OPEN v_cursor FOR
            SELECT
                v_idLog                    AS "uid",
                HANDLE_EXCEPTION
                (v_errorCode, v_errorMessage) AS "message",
                0                          AS "state"
            FROM DUAL;

        RETURN v_cursor;
    END BUILD_ERROR_CURSOR;

END PKG_UTILIDADES;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_UTILIDADES" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package Body PKG_VALIDACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_VALIDACIONES" AS 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- NAME:       pkg_validaciones 
-- PURPOSE:
-- 
-- REVISIONS:
-- Ver        Date        Author           Description
-- ---------  ----------  ---------------  ------------------------------------
-- 1.0        15/10/2025   @author         1. Package generico con diferentes procedimientos de validaciones
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --  


/*
 * @p_texto   : texto de entrada a la cual se va a evaluar su tama�o
 * @p_tamanio : indica la cantidad maxima permitida para el texto que se esta evaluando
 * @return    : devuelve un true, si el tama�o del texto de entrada no sobrepasa el limite 
 *              del tama�o indicado en @p_tamanio           
 */
FUNCTION tamanio_campo( 
                        p_texto     in varchar2 ,         
                        p_tamanio   in number
                      ) return boolean is

Begin


    if length(p_texto) > p_tamanio then  

        return false;

    end if;  

    return true;

exception when others then 

    return false;

end; 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


FUNCTION es_numero( 
                    p_var     in varchar2                  
                  ) return boolean is

v_var  number;

Begin

     v_var := to_number(p_var);

    return true;

exception when others then 

    return false;

end; 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


FUNCTION es_fecha( 
                  p_fecha     in varchar2
                 ) return boolean is


v_fecha date;

Begin

    v_fecha  := to_date(p_fecha);

    return true;

exception when others then 

    return false;

end; 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


END;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDACIONES" TO "SIGESUSTIC";
--------------------------------------------------------
--  DDL for Package Body PKG_VALIDATOR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_VALIDATOR" AS

    -- -------------------------------------------------------------------------
    -- Helpers de tokenizaci�n
    -- -------------------------------------------------------------------------

    FUNCTION GET_TOKEN(p_str VARCHAR2, p_idx PLS_INTEGER, p_sep VARCHAR2 DEFAULT '|')
        RETURN VARCHAR2
    IS
        v_str VARCHAR2(500);
        v_ini PLS_INTEGER;
        v_fin PLS_INTEGER;
    BEGIN
        IF p_str IS NULL THEN RETURN NULL; END IF;
        v_str := p_sep || p_str || p_sep;
        v_ini := INSTR(v_str, p_sep, 1, p_idx);
        v_fin := INSTR(v_str, p_sep, 1, p_idx + 1);
        IF v_ini = 0 OR v_fin = 0 THEN RETURN NULL; END IF;
        RETURN SUBSTR(v_str, v_ini + 1, v_fin - v_ini - 1);
    END;

    FUNCTION COUNT_TOKENS(p_str VARCHAR2, p_sep VARCHAR2 DEFAULT '|')
        RETURN PLS_INTEGER
    IS
        v_len1 PLS_INTEGER;
        v_len2 PLS_INTEGER;
    BEGIN
        IF p_str IS NULL THEN RETURN 0; END IF;
        v_len1 := NVL(LENGTH(p_str), 0);
        v_len2 := NVL(LENGTH(REPLACE(p_str, p_sep, '')), 0);
        RETURN v_len1 - v_len2 + 1;
    END;

    FUNCTION PARSE_NUMBER(p_str IN VARCHAR2) RETURN NUMBER IS
        v_num NUMBER;
    BEGIN
        IF p_str IS NULL THEN RETURN NULL; END IF;

        BEGIN
            v_num := TO_NUMBER(p_str, '999999999999990D999999', 'NLS_NUMERIC_CHARACTERS=.,');
            RETURN v_num;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        BEGIN
            v_num := TO_NUMBER(p_str, '999999999999990D999999', 'NLS_NUMERIC_CHARACTERS=,.');
            RETURN v_num;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        RETURN NULL;
    END;

    FUNCTION PARSE_DATE(p_str IN VARCHAR2, p_fmt IN VARCHAR2) RETURN DATE IS
        v_date DATE;
    BEGIN
        IF p_str IS NULL OR p_fmt IS NULL THEN RETURN NULL; END IF;
        v_date := TO_DATE(p_str, p_fmt);
        RETURN v_date;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
    END;

    -- -------------------------------------------------------------------------
    -- Valida si un valor (VARCHAR2 o CLOB) es un JSON sint�cticamente v�lido.
    -- p_type permite exigir un tipo ra�z espec�fico: 'OBJECT' o 'ARRAY'.
    -- Si p_type es NULL, acepta cualquier JSON v�lido (objeto, array o escalar).
    -- -------------------------------------------------------------------------
    FUNCTION IS_VALID_JSON(p_val IN CLOB, p_type IN VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        v_dummy PLS_INTEGER;
        v_first VARCHAR2(1);
    BEGIN
        -- Validaci�n sint�ctica nativa de Oracle
        SELECT 1 INTO v_dummy FROM DUAL WHERE p_val IS JSON;

        -- Validaci�n opcional de tipo ra�z (compatible con versiones sin
        -- soporte de "IS JSON OBJECT/ARRAY" nativo)
        IF p_type IS NOT NULL THEN
            v_first := SUBSTR(TRIM(p_val), 1, 1);
            IF UPPER(p_type) = 'OBJECT' AND v_first != '{' THEN
                RETURN FALSE;
            ELSIF UPPER(p_type) = 'ARRAY' AND v_first != '[' THEN
                RETURN FALSE;
            END IF;
        END IF;

        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END IS_VALID_JSON;

    -- -------------------------------------------------------------------------
    -- Constructores RULE
    -- -------------------------------------------------------------------------

    FUNCTION RULE(p_name IN VARCHAR2, p_value IN VARCHAR2, p_rules IN VARCHAR2)
        RETURN T_RULE IS
    BEGIN
        RETURN T_RULE(p_name, p_value, NULL, NULL, NULL, p_rules, NULL, NULL);
    END;

    FUNCTION RULE(p_name IN VARCHAR2, p_value IN NUMBER, p_rules IN VARCHAR2)
        RETURN T_RULE IS
    BEGIN
        RETURN T_RULE(p_name, NULL, p_value, NULL, NULL, p_rules, NULL, NULL);
    END;

    -- Overload DATE con soporte de l�mites nativos (p_min_date/p_max_date).
    -- Si no se informan, quedan NULL y las reglas de fecha siguen tomando el
    -- l�mite desde el string de p_rules (compatibilidad hacia atr�s).
    FUNCTION RULE(p_name IN VARCHAR2, p_value IN DATE, p_rules IN VARCHAR2,
                  p_min_date IN DATE DEFAULT NULL,
                  p_max_date IN DATE DEFAULT NULL)
        RETURN T_RULE IS
    BEGIN
        RETURN T_RULE(p_name, NULL, NULL, p_value, NULL, p_rules, p_min_date, p_max_date);
    END;

    -- Nuevo constructor CLOB
    FUNCTION RULE(p_name IN VARCHAR2, p_value IN CLOB, p_rules IN VARCHAR2)
        RETURN T_RULE IS
    BEGIN
        RETURN T_RULE(p_name, NULL, NULL, NULL, p_value, p_rules, NULL, NULL);
    END;

    -- -------------------------------------------------------------------------
    -- Valida una sola regla y devuelve los errores encontrados
    -- -------------------------------------------------------------------------

    FUNCTION VALIDATE_RULE(p_rule IN T_RULE) RETURN T_ERRORS IS
        -- ?? Fechas l�mite hardcodeadas ????????????????????????????????????
        -- Si no se declara min_date/max_date/between_date (ni sus variantes
        -- _datetime) se aplican estos defaults. Comparados por d�a (TRUNC),
        -- igual que min_date/max_date. date_not_future y date_not_past usan
        -- SYSDATE din�mico, no estos valores.
        C_DATE_MIN    CONSTANT DATE := TO_DATE('01/01/1900', 'DD/MM/YYYY');
        C_DATE_MAX    CONSTANT DATE := TO_DATE('31/12/2999', 'DD/MM/YYYY');
        -- ?????????????????????????????????????????????????????????????????
        v_errors     T_ERRORS := T_ERRORS();
        v_n           PLS_INTEGER;
        v_token       VARCHAR2(200);
        v_key         VARCHAR2(100);
        v_param       VARCHAR2(200);
        v_eq_pos      PLS_INTEGER;
        v_is_req      BOOLEAN := FALSE;
        v_is_num      BOOLEAN;
        v_is_date     BOOLEAN;
        v_is_clob     BOOLEAN;
        v_clob_len    INTEGER;
        v_date_fmt    VARCHAR2(100) := 'DD/MM/YYYY';
        v_num         NUMBER;
        v_parsed_dt   DATE;
        v_cmp_date    DATE;
        v_lo_date     DATE;
        v_hi_date     DATE;
        -- Flags para saber si el desarrollador ya declar� l�mites de fecha expl�citos
        -- (por d�a: min_date/max_date/between_date)
        v_has_min_date         BOOLEAN := FALSE;
        v_has_max_date         BOOLEAN := FALSE;
        v_has_between_date     BOOLEAN := FALSE;
        -- (por instante exacto: min_datetime/max_datetime/between_datetime)
        v_has_min_datetime     BOOLEAN := FALSE;
        v_has_max_datetime     BOOLEAN := FALSE;
        v_has_between_datetime BOOLEAN := FALSE;
        v_has_date_rule        BOOLEAN := FALSE; -- TRUE si el campo es DATE o tiene date_fmt

        PROCEDURE ADD_ERROR(p_msg IN VARCHAR2) IS
        BEGIN
            v_errors.EXTEND;
            v_errors(v_errors.COUNT) := p_msg;
        END;

    BEGIN
        v_n        := COUNT_TOKENS(p_rule.p_rules);
        v_is_num   := p_rule.p_value_num  IS NOT NULL;
        v_is_date  := p_rule.p_value_date IS NOT NULL;
        -- CLOB: considerado clob cuando viene por p_value_clob,
        -- independientemente de si tiene contenido o no
        v_is_clob  := p_rule.p_value_clob IS NOT NULL;
        v_clob_len := CASE WHEN v_is_clob
                          THEN DBMS_LOB.GETLENGTH(p_rule.p_value_clob)
                          ELSE NULL
                     END;

        -- Primera pasada: detectar date_fmt, required y flags de fecha
        -- v_has_date_rule se activa si el campo es DATE nativo o tiene date_fmt en las reglas
        v_has_date_rule := v_is_date OR (INSTR(p_rule.p_rules, 'date_fmt') > 0);

        FOR j IN 1 .. v_n LOOP
            v_token  := TRIM(GET_TOKEN(p_rule.p_rules, j));
            v_eq_pos := INSTR(v_token, '=');
            IF v_eq_pos > 0 THEN
                v_key   := SUBSTR(v_token, 1, v_eq_pos - 1);
                v_param := SUBSTR(v_token, v_eq_pos + 1);
            ELSE
                v_key := v_token; v_param := NULL;
            END IF;
            IF v_key = 'required'          THEN v_is_req              := TRUE;    END IF;
            IF v_key = 'persona'           THEN v_is_req              := TRUE;    END IF;
            IF v_key = 'date_fmt'          THEN v_date_fmt            := v_param; END IF;
            IF v_key = 'min_date'          THEN v_has_min_date         := TRUE;   END IF;
            IF v_key = 'max_date'          THEN v_has_max_date         := TRUE;   END IF;
            IF v_key = 'between_date'      THEN v_has_between_date     := TRUE;   END IF;
            IF v_key = 'min_datetime'      THEN v_has_min_datetime     := TRUE;   END IF;
            IF v_key = 'max_datetime'      THEN v_has_max_datetime     := TRUE;   END IF;
            IF v_key = 'between_datetime'  THEN v_has_between_datetime := TRUE;   END IF;
        END LOOP;

        -- Validar required
        IF v_is_req THEN
            IF v_is_num  AND p_rule.p_value_num  IS NULL THEN
                ADD_ERROR(p_rule.p_name || ' es obligatorio.');
                RETURN v_errors;
            ELSIF v_is_date AND p_rule.p_value_date IS NULL THEN
                ADD_ERROR(p_rule.p_name || ' es obligatorio.');
                RETURN v_errors;
            ELSIF v_is_clob AND (v_clob_len IS NULL OR v_clob_len = 0) THEN
                -- CLOB vac�o o nulo se considera no cumple required
                ADD_ERROR(p_rule.p_name || ' es obligatorio.');
                RETURN v_errors;
            ELSIF NOT v_is_num AND NOT v_is_date AND NOT v_is_clob
                  AND p_rule.p_value_str IS NULL THEN
                ADD_ERROR(p_rule.p_name || ' es obligatorio.');
                RETURN v_errors;
            END IF;
        END IF;

        -- Todo nulo, nada que validar
        IF p_rule.p_value_num  IS NULL AND
           p_rule.p_value_str  IS NULL AND
           p_rule.p_value_date IS NULL AND
           p_rule.p_value_clob IS NULL THEN
            RETURN v_errors;
        END IF;

        -- Pre-parseo de fecha desde string
        -- v_has_date_rule ya fue calculado en la primera pasada.
        -- Si el campo tiene regla de fecha, parsear el string ahora para
        -- que est� disponible tanto en la segunda pasada como en los defaults.
        v_parsed_dt := NULL;
        IF NOT v_is_num AND NOT v_is_date AND NOT v_is_clob
           AND p_rule.p_value_str IS NOT NULL THEN
            IF v_has_date_rule                                OR
               INSTR(p_rule.p_rules, 'min_date')            > 0 OR
               INSTR(p_rule.p_rules, 'max_date')            > 0 OR
               INSTR(p_rule.p_rules, 'between_date')        > 0 OR
               INSTR(p_rule.p_rules, 'min_datetime')        > 0 OR
               INSTR(p_rule.p_rules, 'max_datetime')        > 0 OR
               INSTR(p_rule.p_rules, 'between_datetime')    > 0 OR
               INSTR(p_rule.p_rules, 'date_not_future')     > 0 OR
               INSTR(p_rule.p_rules, 'date_not_past')       > 0 THEN
                v_parsed_dt := PARSE_DATE(p_rule.p_value_str, v_date_fmt);
            END IF;
        END IF;

        -- Segunda pasada: aplicar cada regla
        FOR j IN 1 .. v_n LOOP
            v_token  := TRIM(GET_TOKEN(p_rule.p_rules, j));
            v_eq_pos := INSTR(v_token, '=');
            IF v_eq_pos > 0 THEN
                v_key   := SUBSTR(v_token, 1, v_eq_pos - 1);
                v_param := SUBSTR(v_token, v_eq_pos + 1);
            ELSE
                v_key := v_token; v_param := NULL;
            END IF;

            -- ---- Reglas num�ricas ----------------------------------------

            IF v_key = 'int' THEN
                IF v_is_clob THEN NULL; -- no aplica a CLOB
                ELSIF v_is_num THEN
                    IF p_rule.p_value_num != TRUNC(p_rule.p_value_num) THEN
                        ADD_ERROR(p_rule.p_name || ' debe ser un n�mero entero.');
                    END IF;
                ELSE
                    v_num := PARSE_NUMBER(p_rule.p_value_str);
                    IF v_num IS NULL OR v_num != TRUNC(v_num) THEN
                        ADD_ERROR(p_rule.p_name || ' debe ser un n�mero entero.');
                    END IF;
                END IF;

            ELSIF v_key = 'float' THEN
                IF v_is_clob THEN NULL; -- no aplica a CLOB
                ELSIF NOT v_is_num THEN
                    v_num := PARSE_NUMBER(p_rule.p_value_str);
                    IF v_num IS NULL THEN
                        ADD_ERROR(p_rule.p_name || ' debe ser un n�mero v�lido.');
                    END IF;
                END IF;

            -- ----------------------------------------------------------------
            -- max / min:
            --   NUMBER   ? comparar por valor num�rico
            --   VARCHAR2 ? comparar siempre por LENGTH (fix bug Samuel)
            --   CLOB     ? comparar por DBMS_LOB.GETLENGTH
            -- ----------------------------------------------------------------

            ELSIF v_key = 'max' THEN
                IF v_is_num THEN
                    IF p_rule.p_value_num > TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' excede el m�ximo de ' || v_param || '.');
                    END IF;
                ELSIF v_is_clob THEN
                    IF NVL(v_clob_len, 0) > TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' excede el m�ximo de ' || v_param || ' caracteres.');
                    END IF;
                ELSE
                    -- VARCHAR2: siempre por longitud, nunca por valor num�rico
                    IF LENGTH(p_rule.p_value_str) > TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' excede el m�ximo de ' || v_param || ' caracteres.');
                    END IF;
                END IF;

            ELSIF v_key = 'min' THEN
                IF v_is_num THEN
                    IF p_rule.p_value_num < TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' debe ser m�nimo ' || v_param || '.');
                    END IF;
                ELSIF v_is_clob THEN
                    IF NVL(v_clob_len, 0) < TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' debe tener al menos ' || v_param || ' caracteres.');
                    END IF;
                ELSE
                    -- VARCHAR2: siempre por longitud
                    IF LENGTH(p_rule.p_value_str) < TO_NUMBER(v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' debe tener al menos ' || v_param || ' caracteres.');
                    END IF;
                END IF;

            ELSIF v_key = 'between' THEN
                IF v_is_clob THEN NULL; -- between num�rico no aplica a CLOB
                ELSE
                    DECLARE
                        v_lo NUMBER := TO_NUMBER(GET_TOKEN(v_param, 1, ','));
                        v_hi NUMBER := TO_NUMBER(GET_TOKEN(v_param, 2, ','));
                    BEGIN
                        IF v_is_num THEN
                            IF p_rule.p_value_num < v_lo OR p_rule.p_value_num > v_hi THEN
                                ADD_ERROR(p_rule.p_name || ' debe estar entre ' || v_lo || ' y ' || v_hi || '.');
                            END IF;
                        ELSE
                            v_num := PARSE_NUMBER(p_rule.p_value_str);
                            IF v_num IS NULL OR v_num < v_lo OR v_num > v_hi THEN
                                ADD_ERROR(p_rule.p_name || ' debe estar entre ' || v_lo || ' y ' || v_hi || '.');
                            END IF;
                        END IF;
                    END;
                END IF;

            ELSIF v_key = 'in_list' THEN
                IF v_is_clob THEN NULL; -- in_list no aplica a CLOB
                ELSE
                    DECLARE
                        v_found BOOLEAN       := FALSE;
                        v_opts  PLS_INTEGER   := COUNT_TOKENS(v_param, ',');
                        v_val   VARCHAR2(200) := NVL(p_rule.p_value_str, TO_CHAR(p_rule.p_value_num));
                    BEGIN
                        FOR k IN 1 .. v_opts LOOP
                            IF TRIM(GET_TOKEN(v_param, k, ',')) = TRIM(v_val) THEN
                                v_found := TRUE;
                            END IF;
                        END LOOP;
                        IF NOT v_found THEN
                            ADD_ERROR(p_rule.p_name || ' tiene un valor no permitido.');
                        END IF;
                    END;
                END IF;

            ELSIF v_key = 'not_exists' THEN
                IF v_is_clob THEN NULL; -- not_exists no aplica a CLOB
                ELSE
                    DECLARE
                        v_found BOOLEAN       := FALSE;
                        v_opts  PLS_INTEGER   := COUNT_TOKENS(v_param, ',');
                        v_val   VARCHAR2(200) := NVL(p_rule.p_value_str, TO_CHAR(p_rule.p_value_num));
                    BEGIN
                        FOR k IN 1 .. v_opts LOOP
                            IF TRIM(GET_TOKEN(v_param, k, ',')) = TRIM(v_val) THEN
                                v_found := TRUE;
                            END IF;
                        END LOOP;
                        IF v_found THEN
                            ADD_ERROR(p_rule.p_name || ' tiene un valor no permitido.');
                        END IF;
                    END;
                END IF;

            -- ---- Regla email ---------------------------------------------
            -- Solo aplica a VARCHAR2. CLOB no tiene sentido para un email.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'email' THEN
                IF v_is_clob THEN NULL; -- email no aplica a CLOB
                ELSIF NOT v_is_num AND NOT v_is_date THEN
                    IF p_rule.p_value_str IS NOT NULL THEN
                        IF NOT REGEXP_LIKE(
                            p_rule.p_value_str,
                            '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$'
                        ) THEN
                            ADD_ERROR(p_rule.p_name || ' no tiene un formato de correo v�lido.');
                        END IF;
                    END IF;
                END IF;

            -- ---- json / json=object / json=array --------------------------
            -- Valida que el valor sea un JSON sint�cticamente correcto.
            -- Aplica a VARCHAR2 y a CLOB. No aplica a NUMBER ni DATE.
            -- Par�metro opcional: OBJECT o ARRAY para exigir tipo ra�z espec�fico.
            -- Ejemplo: 'clob|required|json'  �  'clob|required|json=object'
            -- ----------------------------------------------------------------

            ELSIF v_key = 'json' THEN
                IF v_is_num OR v_is_date THEN
                    NULL; -- no aplica
                ELSIF v_is_clob THEN
                    IF v_clob_len > 0 AND NOT IS_VALID_JSON(p_rule.p_value_clob, v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' debe contener un JSON v�lido' ||
                            CASE WHEN v_param IS NOT NULL
                                 THEN ' de tipo ' || LOWER(v_param)
                                 ELSE ''
                            END || '.');
                    END IF;
                ELSE
                    IF p_rule.p_value_str IS NOT NULL AND NOT IS_VALID_JSON(p_rule.p_value_str, v_param) THEN
                        ADD_ERROR(p_rule.p_name || ' debe contener un JSON v�lido' ||
                            CASE WHEN v_param IS NOT NULL
                                 THEN ' de tipo ' || LOWER(v_param)
                                 ELSE ''
                            END || '.');
                    END IF;
                END IF;

            -- ---- max_decimals=N ------------------------------------------
            -- Valida que un n�mero no tenga m�s de N decimales.
            -- Aplica a NUMBER y a VARCHAR2 parseables como n�mero.
            -- Ejemplo: max_decimals=2 ? 123.456 falla, 123.45 pasa.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'max_decimals' THEN
                IF v_is_clob OR v_is_date THEN NULL;
                ELSE
                    DECLARE
                        v_dec     PLS_INTEGER := TO_NUMBER(v_param);
                        v_factor  NUMBER;
                        v_tmpnum  NUMBER;
                    BEGIN
                        v_tmpnum := CASE WHEN v_is_num
                                        THEN p_rule.p_value_num
                                        ELSE PARSE_NUMBER(p_rule.p_value_str)
                                   END;
                        IF v_tmpnum IS NOT NULL THEN
                            v_factor := POWER(10, v_dec);
                            IF v_tmpnum * v_factor != TRUNC(v_tmpnum * v_factor) THEN
                                ADD_ERROR(p_rule.p_name || ' no puede tener m�s de ' || v_param || ' decimal(es).');
                            END IF;
                        END IF;
                    END;
                END IF;

            -- ---- positive ------------------------------------------------
            -- Shortcut sem�ntico para n�mero > 0.
            -- Aplica a NUMBER y a VARCHAR2 parseables como n�mero.
            -- M�s legible que min=1 cuando el dominio exige valor positivo.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'positive' THEN
                IF v_is_clob OR v_is_date THEN NULL;
                ELSE
                    DECLARE
                        v_tmpnum NUMBER;
                    BEGIN
                        v_tmpnum := CASE WHEN v_is_num
                                        THEN p_rule.p_value_num
                                        ELSE PARSE_NUMBER(p_rule.p_value_str)
                                   END;
                        IF v_tmpnum IS NULL OR v_tmpnum <= 0 THEN
                            ADD_ERROR(p_rule.p_name || ' debe ser un valor positivo mayor a cero.');
                        END IF;
                    END;
                END IF;

            -- ---- date_not_future -----------------------------------------
            -- La fecha no puede ser posterior a hoy (TRUNC(SYSDATE)).
            -- Aplica a DATE y a VARCHAR2 con formato date_fmt.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'date_not_future' THEN
                IF v_is_clob THEN NULL;
                ELSIF v_is_date THEN
                    IF TRUNC(p_rule.p_value_date) > TRUNC(SYSDATE) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser una fecha futura.');
                    END IF;
                ELSE
                    IF v_parsed_dt IS NULL OR TRUNC(v_parsed_dt) > TRUNC(SYSDATE) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser una fecha futura.');
                    END IF;
                END IF;

            -- ---- date_not_past -------------------------------------------
            -- La fecha no puede ser anterior a hoy (TRUNC(SYSDATE)).
            -- Aplica a DATE y a VARCHAR2 con formato date_fmt.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'date_not_past' THEN
                IF v_is_clob THEN NULL;
                ELSIF v_is_date THEN
                    IF TRUNC(p_rule.p_value_date) < TRUNC(SYSDATE) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser una fecha pasada.');
                    END IF;
                ELSE
                    IF v_parsed_dt IS NULL OR TRUNC(v_parsed_dt) < TRUNC(SYSDATE) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser una fecha pasada.');
                    END IF;
                END IF;

            -- ---- regex=patron --------------------------------------------
            -- Valida que el valor cumpla la expresi�n regular indicada.
            -- Solo aplica a VARCHAR2. �til para RUT, tel�fono, c�digo, etc.
            -- Ejemplo: regex=^[0-9]{7,8}-[0-9Kk]$
            -- ----------------------------------------------------------------

            ELSIF v_key = 'regex' THEN
                IF v_is_clob OR v_is_num OR v_is_date THEN NULL;
                ELSE
                    IF p_rule.p_value_str IS NOT NULL THEN
                        IF NOT REGEXP_LIKE(p_rule.p_value_str, v_param) THEN
                            ADD_ERROR(p_rule.p_name || ' no tiene un formato v�lido.');
                        END IF;
                    END IF;
                END IF;

            -- ---- Reglas de fecha -----------------------------------------

            ELSIF v_key = 'date_fmt' THEN
                IF v_is_clob THEN NULL;
                ELSIF NOT v_is_date THEN
                    IF PARSE_DATE(p_rule.p_value_str, v_param) IS NULL THEN
                        ADD_ERROR(p_rule.p_name || ' no tiene un formato de fecha v�lido (' || v_param || ').');
                    END IF;
                END IF;

            -- ---- min_date --------------------------------------------------
            -- ORIGINAL: compara por d�a (TRUNC), ignora hora/minuto/segundo.
            -- ------------------------------------------------------------------

            ELSIF v_key = 'min_date' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_lo IS NOT NULL THEN
                        v_cmp_date := p_rule.p_cmp_date_lo;
                    ELSE
                        v_cmp_date := TO_DATE(v_param, v_date_fmt);
                    END IF;

                    IF v_cmp_date IS NOT NULL THEN
                        IF v_is_date THEN
                            IF TRUNC(p_rule.p_value_date) < TRUNC(v_cmp_date) THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser anterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY') || '.');
                            END IF;
                        ELSE
                            IF v_parsed_dt IS NULL OR TRUNC(v_parsed_dt) < TRUNC(v_cmp_date) THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser anterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY') || '.');
                            END IF;
                        END IF;
                    END IF;
                END IF;

            -- ---- max_date --------------------------------------------------
            -- ORIGINAL: compara por d�a (TRUNC), ignora hora/minuto/segundo.
            -- ------------------------------------------------------------------

            ELSIF v_key = 'max_date' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_hi IS NOT NULL THEN
                        v_cmp_date := p_rule.p_cmp_date_hi;
                    ELSE
                        v_cmp_date := TO_DATE(v_param, v_date_fmt);
                    END IF;

                    IF v_cmp_date IS NOT NULL THEN
                        IF v_is_date THEN
                            IF TRUNC(p_rule.p_value_date) > TRUNC(v_cmp_date) THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser posterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY') || '.');
                            END IF;
                        ELSE
                            IF v_parsed_dt IS NULL OR TRUNC(v_parsed_dt) > TRUNC(v_cmp_date) THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser posterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY') || '.');
                            END IF;
                        END IF;
                    END IF;
                END IF;

            -- ---- between_date -----------------------------------------------
            -- ORIGINAL: compara por d�a (TRUNC), ignora hora/minuto/segundo.
            -- --------------------------------------------------------------------

            ELSIF v_key = 'between_date' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_lo IS NOT NULL AND p_rule.p_cmp_date_hi IS NOT NULL THEN
                        v_lo_date := p_rule.p_cmp_date_lo;
                        v_hi_date := p_rule.p_cmp_date_hi;
                    ELSE
                        DECLARE
                            v_p1 VARCHAR2(100) := GET_TOKEN(v_param, 1, ',');
                            v_p2 VARCHAR2(100) := GET_TOKEN(v_param, 2, ',');
                        BEGIN
                            v_lo_date := TO_DATE(v_p1, v_date_fmt);
                            v_hi_date := TO_DATE(v_p2, v_date_fmt);
                        END;
                    END IF;

                    IF v_is_date THEN
                        IF TRUNC(p_rule.p_value_date) < TRUNC(v_lo_date) OR
                           TRUNC(p_rule.p_value_date) > TRUNC(v_hi_date) THEN
                            ADD_ERROR(p_rule.p_name || ' debe estar entre ' ||
                                TO_CHAR(v_lo_date, 'DD/MM/YYYY') || ' y ' ||
                                TO_CHAR(v_hi_date, 'DD/MM/YYYY') || '.');
                        END IF;
                    ELSE
                        IF v_parsed_dt IS NULL OR
                           TRUNC(v_parsed_dt) < TRUNC(v_lo_date) OR
                           TRUNC(v_parsed_dt) > TRUNC(v_hi_date) THEN
                            ADD_ERROR(p_rule.p_name || ' debe estar entre ' ||
                                TO_CHAR(v_lo_date, 'DD/MM/YYYY') || ' y ' ||
                                TO_CHAR(v_hi_date, 'DD/MM/YYYY') || '.');
                        END IF;
                    END IF;
                END IF;

            -- ---- min_datetime ------------------------------------------------
            -- NUEVA: compara por instante exacto (d�a, hora, minuto, segundo).
            -- Prioridad del l�mite:
            --   1) p_rule.p_cmp_date_lo (DATE nativo, v�a RULE(..., p_min_date => ...))
            --   2) v_param (string parseado con date_fmt, debe incluir hora)
            -- --------------------------------------------------------------------

            ELSIF v_key = 'min_datetime' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_lo IS NOT NULL THEN
                        v_cmp_date := p_rule.p_cmp_date_lo;
                    ELSE
                        v_cmp_date := TO_DATE(v_param, v_date_fmt);
                    END IF;

                    IF v_cmp_date IS NOT NULL THEN
                        IF v_is_date THEN
                            IF p_rule.p_value_date < v_cmp_date THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser anterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                            END IF;
                        ELSE
                            IF v_parsed_dt IS NULL OR v_parsed_dt < v_cmp_date THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser anterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                            END IF;
                        END IF;
                    END IF;
                END IF;

            -- ---- max_datetime ------------------------------------------------
            -- NUEVA: compara por instante exacto (d�a, hora, minuto, segundo).
            -- Prioridad del l�mite:
            --   1) p_rule.p_cmp_date_hi (DATE nativo, v�a RULE(..., p_max_date => ...))
            --   2) v_param (string parseado con date_fmt, debe incluir hora)
            -- --------------------------------------------------------------------

            ELSIF v_key = 'max_datetime' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_hi IS NOT NULL THEN
                        v_cmp_date := p_rule.p_cmp_date_hi;
                    ELSE
                        v_cmp_date := TO_DATE(v_param, v_date_fmt);
                    END IF;

                    IF v_cmp_date IS NOT NULL THEN
                        IF v_is_date THEN
                            IF p_rule.p_value_date > v_cmp_date THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser posterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                            END IF;
                        ELSE
                            IF v_parsed_dt IS NULL OR v_parsed_dt > v_cmp_date THEN
                                ADD_ERROR(p_rule.p_name || ' no puede ser posterior a ' ||
                                    TO_CHAR(v_cmp_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                            END IF;
                        END IF;
                    END IF;
                END IF;

            -- ---- between_datetime ---------------------------------------------
            -- NUEVA: compara por instante exacto (d�a, hora, minuto, segundo).
            -- Prioridad de l�mites:
            --   1) p_rule.p_cmp_date_lo Y p_rule.p_cmp_date_hi (ambos DATE nativos)
            --   2) v_param (string "lo,hi" parseado con date_fmt, debe incluir hora)
            -- ----------------------------------------------------------------------

            ELSIF v_key = 'between_datetime' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    IF p_rule.p_cmp_date_lo IS NOT NULL AND p_rule.p_cmp_date_hi IS NOT NULL THEN
                        v_lo_date := p_rule.p_cmp_date_lo;
                        v_hi_date := p_rule.p_cmp_date_hi;
                    ELSE
                        DECLARE
                            v_p1 VARCHAR2(100) := GET_TOKEN(v_param, 1, ',');
                            v_p2 VARCHAR2(100) := GET_TOKEN(v_param, 2, ',');
                        BEGIN
                            v_lo_date := TO_DATE(v_p1, v_date_fmt);
                            v_hi_date := TO_DATE(v_p2, v_date_fmt);
                        END;
                    END IF;

                    IF v_is_date THEN
                        IF p_rule.p_value_date < v_lo_date OR p_rule.p_value_date > v_hi_date THEN
                            ADD_ERROR(p_rule.p_name || ' debe estar entre ' ||
                                TO_CHAR(v_lo_date, 'DD/MM/YYYY HH24:MI:SS') || ' y ' ||
                                TO_CHAR(v_hi_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                        END IF;
                    ELSE
                        IF v_parsed_dt IS NULL OR
                           v_parsed_dt < v_lo_date OR
                           v_parsed_dt > v_hi_date THEN
                            ADD_ERROR(p_rule.p_name || ' debe estar entre ' ||
                                TO_CHAR(v_lo_date, 'DD/MM/YYYY HH24:MI:SS') || ' y ' ||
                                TO_CHAR(v_hi_date, 'DD/MM/YYYY HH24:MI:SS') || '.');
                        END IF;
                    END IF;
                END IF;

            ELSIF v_key = 'persona' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    DECLARE
                        v_idPersona NUMBER;
                    BEGIN
                        v_idPersona := NVL(p_rule.p_value_num, PARSE_NUMBER(p_rule.p_value_str));
                        BEGIN
                            UTILIDADES.VALIDATE_PERSONA(v_idPersona);
                        EXCEPTION WHEN OTHERS THEN
                            ADD_ERROR(p_rule.p_name || ' la persona no existe.');
                        END;
                    EXCEPTION WHEN VALUE_ERROR THEN
                        ADD_ERROR(p_rule.p_name || ' tiene un valor no permitido.');
                    END;
                END IF;

            -- ---- Regla clob -----------------------------------------------
            -- Declara que el campo soporta datos grandes.
            -- El par�metro DEBE estar declarado como CLOB en la firma del procedure.
            -- Si llega como VARCHAR2 (p_value_str) se lanza error indicando al
            -- desarrollador que debe cambiar el tipo del par�metro a CLOB.
            -- Si llega como CLOB (p_value_clob) se usa DBMS_LOB.GETLENGTH
            -- para max/min/required, soportando cualquier tama�o incluyendo valores cortos.
            -- ----------------------------------------------------------------

            ELSIF v_key = 'clob' THEN
                IF NOT v_is_clob THEN
                    -- Lleg� como VARCHAR2 pero tiene regla clob ? el par�metro debe ser CLOB
                    ADD_ERROR(p_rule.p_name || ': declare el par�metro como CLOB para soportar datos grandes.');
                    RETURN v_errors;
                END IF;
                -- Si es CLOB, max/min/required ya lo manejan con DBMS_LOB.GETLENGTH

            ELSIF v_key = 'referencia' THEN
                IF v_is_clob THEN NULL;
                ELSE
                    DECLARE
                        v_refPadre NUMBER;
                        v_refItem  NUMBER;
                    BEGIN
                        IF TRIM(v_param) IS NULL THEN
                            ADD_ERROR(p_rule.p_name || ' referencia padre es obligatorio.');
                            GOTO next_token;
                        END IF;

                        v_refPadre := TO_NUMBER(v_param);
                        v_refItem  := NVL(p_rule.p_value_num, PARSE_NUMBER(p_rule.p_value_str));

                        BEGIN
                            UTILIDADES.VALIDATE_ITEM(v_refPadre, v_refItem);
                        EXCEPTION WHEN OTHERS THEN
                            ADD_ERROR(p_rule.p_name || ' item no encontrado.');
                        END;

                    EXCEPTION WHEN VALUE_ERROR THEN
                        ADD_ERROR(p_rule.p_name || ' tiene un valor no permitido.');
                    END;
                END IF;

            END IF;

            <<next_token>> NULL;

        END LOOP;

        -- ?? Aplicar fechas default si el campo es fecha y no se declararon l�mites ??
        -- Solo act�a cuando:
        --   1. El campo es DATE nativo O tiene date_fmt en las reglas (v_has_date_rule)
        --   2. No se declar� between_date NI between_datetime
        --   3. No se declar� min_date/min_datetime y/o max_date/max_datetime
        -- date_not_future y date_not_past NO se ven afectados (usan SYSDATE din�mico)
        -- Comparaci�n por d�a (TRUNC), igual que el comportamiento original.
        -- ?????????????????????????????????????????????????????????????????????????????
        IF v_has_date_rule AND NOT v_has_between_date AND NOT v_has_between_datetime THEN

            -- Aplicar min default si no se declar� min_date ni min_datetime
            IF NOT v_has_min_date AND NOT v_has_min_datetime THEN
                IF v_is_date THEN
                    IF TRUNC(p_rule.p_value_date) < TRUNC(C_DATE_MIN) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser anterior a 01/01/1900.');
                    END IF;
                ELSIF v_parsed_dt IS NOT NULL THEN
                    IF TRUNC(v_parsed_dt) < TRUNC(C_DATE_MIN) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser anterior a 01/01/1900.');
                    END IF;
                END IF;
            END IF;

            -- Aplicar max default si no se declar� max_date ni max_datetime
            IF NOT v_has_max_date AND NOT v_has_max_datetime THEN
                IF v_is_date THEN
                    IF TRUNC(p_rule.p_value_date) > TRUNC(C_DATE_MAX) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser posterior a 31/12/2999.');
                    END IF;
                ELSIF v_parsed_dt IS NOT NULL THEN
                    IF TRUNC(v_parsed_dt) > TRUNC(C_DATE_MAX) THEN
                        ADD_ERROR(p_rule.p_name || ' no puede ser posterior a 31/12/2999.');
                    END IF;
                END IF;
            END IF;

        END IF;

        RETURN v_errors;
    END VALIDATE_RULE;

    -- -------------------------------------------------------------------------
    -- VALIDATE: fail-fast, lanza al primer error
    -- -------------------------------------------------------------------------

    PROCEDURE VALIDATE(p_list IN T_RULES) IS
        v_errs T_ERRORS;
    BEGIN
        FOR i IN 1 .. p_list.COUNT LOOP
            v_errs := VALIDATE_RULE(p_list(i));
            IF v_errs.COUNT > 0 THEN
                RAISE_APPLICATION_ERROR(CONST.ERROR_VALIDATOR, v_errs(1));
            END IF;
        END LOOP;
    END VALIDATE;

    -- -------------------------------------------------------------------------
    -- GET_ERRORS: devuelve colecci�n sin lanzar
    -- -------------------------------------------------------------------------

    FUNCTION GET_ERRORS(p_list IN T_RULES) RETURN T_ERRORS IS
        v_all  T_ERRORS := T_ERRORS();
        v_errs T_ERRORS;
    BEGIN
        FOR i IN 1 .. p_list.COUNT LOOP
            v_errs := VALIDATE_RULE(p_list(i));
            IF v_errs.COUNT > 0 THEN
                FOR k IN 1 .. v_errs.COUNT LOOP
                    v_all.EXTEND;
                    v_all(v_all.COUNT) := v_errs(k);
                END LOOP;
            END IF;
        END LOOP;
        RETURN v_all;
    END GET_ERRORS;

    -- -------------------------------------------------------------------------
    -- VALIDATE_ALL: acumula todos y lanza juntos
    -- -------------------------------------------------------------------------

    PROCEDURE VALIDATE_ALL(p_list IN T_RULES) IS
        v_all T_ERRORS;
        v_msg VARCHAR2(4000) := '';
    BEGIN
        v_all := GET_ERRORS(p_list);
        IF v_all.COUNT > 0 THEN
            FOR i IN 1 .. v_all.COUNT LOOP
                v_msg := v_msg || i || ') ' || v_all(i) || CHR(10);
            END LOOP;
            RAISE_APPLICATION_ERROR(CONST.ERROR_VALIDATOR,
                v_all.COUNT || ' error(es) encontrado(s):' || CHR(10) || v_msg);
        END IF;
    END VALIDATE_ALL;

END PKG_VALIDATOR;

/

  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SECRETARIAGRALDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SIGESUSTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "SIEVAUTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "DACIDTIC";
  GRANT EXECUTE ON "GENERALIDADES"."PKG_VALIDATOR" TO "CALIDAD";
--------------------------------------------------------
--  DDL for Package Body PKG_VISORES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENERALIDADES"."PKG_VISORES" AS

  PROCEDURE GETALL_LOG_SYSTEM (
        p_param                 NUMBER,
        p_cursor                OUT SYS_REFCURSOR
    ) AS

        v_errorCode    NUMBER;
        v_errorMessage VARCHAR2(512);
        
    BEGIN
        OPEN p_cursor FOR
          SELECT *
            FROM (
                   SELECT LOG_ID, APP_ID, DECODE(APP_ID, 38, 'Notificaciones', 4, 'SGU', 5, 'Gesti�n de archivos', 6, 'Parametros', 7, 'Referencias', 8, 'Referencias') APP_DESC, 
                          decode(TIPO, 1681, 'Debug', 1684, 'Warning', 1683, 'Error', 1682, 'Informacion') TIPO, ORIGEN, LOG_JSON, 
                          --PKG_REFERENCIA_ITEM.GETNOMBRE_REFERENCIAITEM(TIPO) TESTING,
                 --         test,
                          TO_CHAR(FECHA_REG, 'DD/MM/YYYY HH24:MI:SS') FECHA_REG,
                          ROW_NUMBER() OVER (ORDER BY FECHA_REG DESC) AS ROW_NUM
                          FROM AUDITOR.LOG_SYSTEM 
                          WHERE (p_param = 1 AND FECHA_REG BETWEEN SYSDATE - 7 AND SYSDATE)
                             OR (p_param = 0)
                          ORDER BY FECHA_REG DESC
                 )
            WHERE (p_param = 1)
               OR (p_param = 0 AND ROW_NUM <= 25);
            
            
        EXCEPTION WHEN OTHERS THEN
        
        v_errorCode := SQLCODE;
            v_errorMessage := SQLERRM;
            
            OPEN p_cursor FOR
            SELECT 
                0                      AS "uid", 
                UTILIDADES.HANDLE_EXCEPTION
                (v_errorCode,v_errorMessage) AS "message", 
                0                            AS "state"
            FROM DUAL;
            
    END GETALL_LOG_SYSTEM;
    
    PROCEDURE GETALL_AUDITOR (
        p_table                 VARCHAR2,
        p_fetch                 VARCHAR2,
        p_limit                 NUMBER DEFAULT 0,
        p_date                  TIMESTAMP DEFAULT NULL,
        p_cursor                OUT SYS_REFCURSOR
    ) AS
    
        v_date_fmt  DATE;
        v_query     CLOB;
        v_exists    NUMBER := 0;
        ex_noData   EXCEPTION;
        
    BEGIN
    
           
        VALIDATOR.VALIDATE(T_RULES(
            VALIDATOR.RULE('table', p_table,                'required|string'),
            VALIDATOR.RULE('fetch', upper(p_fetch),         'required|string|in_list=ALL,INS,UPD,DEL'),
            VALIDATOR.RULE('limit', p_limit,                'required|int|in_list=0,1')
            --VALIDATOR.RULE('limit', v_date_fmt,             'date_fmt=DD/MM/YYYY') -- ToDo: validar fechas nulas 
        ));
        
        SELECT 1
          INTO v_exists
          FROM ALL_TABLES
         WHERE OWNER = 'AUDITOR'
           AND TABLE_NAME = p_table;

        IF v_exists = 0 THEN
            RAISE ex_noData;
        END IF;
        
            v_query := 'SELECT * FROM AUDITOR.' || UPPER(p_table) ||
                       ' WHERE AUD_TIPO = DECODE(''' || p_fetch || ''', ''ALL'', AUD_TIPO, ''' || p_fetch || ''')';
            
            IF p_date IS NOT NULL THEN
            
                v_query := v_query || ' AND AUD_SYSDATE >= TO_TIMESTAMP(''' || 
                                       TO_CHAR(p_date, 'DD/MM/YYYY HH24:MI:SS.FF3') || 
                                       ''', ''DD/MM/YYYY HH24:MI:SS.FF3'')';
                                       
            END IF;
            
            IF(p_limit = 0) THEN -- si viene un 1, ignora esto y devuelve todo
            
                v_query := v_query || ' FETCH FIRST 25 ROWS ONLY';
                
            END IF;
        
        OPEN p_cursor FOR v_query;
           
    EXCEPTION WHEN OTHERS THEN
    
        OPEN p_cursor FOR
            SELECT * FROM dual WHERE 1 = 0;
            
    END GETALL_AUDITOR;
    
    PROCEDURE GETSTATS_LOG_SYSTEM(p_cursor OUT SYS_REFCURSOR) AS
    
    BEGIN
    
        OPEN p_cursor FOR
            SELECT B.CUENTA_TOTAL,
                   A.CUENTA_TOTAL_7DIAS,
                   C.DIA,
                   C.TOTAL TOTAL_DIA,
                   A.ID_ULTIMO,
                   TO_CHAR(A.FECHA, 'DD/MM/YYYY HH:MI:SS') FECHA_ULTIMO
              FROM (
                   SELECT COUNT('X')       AS CUENTA_TOTAL_7DIAS,
                          MAX(LOG_ID)      AS ID_ULTIMO,
                          MAX(FECHA_REG)   AS FECHA
                     FROM AUDITOR.LOG_SYSTEM
                    WHERE FECHA_REG BETWEEN SYSDATE - 7 AND SYSDATE
                ) A,
                (
                   SELECT COUNT('X')       AS CUENTA_TOTAL,
                          MAX(LOG_ID)      AS ID_ULTIMO,
                          MAX(FECHA_REG)   AS FECHA
                     FROM AUDITOR.LOG_SYSTEM
                ) B,
               (
                   SELECT TRIM(INITCAP(TO_CHAR(FECHA_REG, 'DAY', 'NLS_DATE_LANGUAGE=SPANISH'))) AS DIA,
                          COUNT('X') AS TOTAL
                     FROM AUDITOR.LOG_SYSTEM
                    WHERE FECHA_REG BETWEEN SYSDATE - 7 AND SYSDATE
                    GROUP BY TO_CHAR(FECHA_REG, 'DAY', 'NLS_DATE_LANGUAGE=SPANISH')
                    ORDER BY TOTAL DESC
                    FETCH FIRST 1 ROW ONLY
               ) C;
   
    END GETSTATS_LOG_SYSTEM;

END PKG_VISORES;

/
