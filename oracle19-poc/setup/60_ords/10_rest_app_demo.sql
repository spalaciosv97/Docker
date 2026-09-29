-- =====================================================================
-- 10_rest_app_demo.sql — APP_DEMO expuesto por ORDS
--
-- Ejecutar CONECTADO COMO APP_DEMO. El package ORDS tiene EXECUTE para
-- PUBLIC y un esquema puede habilitarse a si mismo, asi que no hace
-- falta repartir ORDS_ADMINISTRATOR_ROLE.
--
-- Deja dos endpoints, y los dos son IDENTICOS en las variantes con y
-- sin APEX. Es deliberado: la unica diferencia entre ambas imagenes es
-- si APEX esta instalado en la base, asi que lo que le pase a
-- /prueba-apex en cada una se explica solo por eso.
--
-- Y los dos endpoints son el MISMO bloque PL/SQL, con el mismo
-- owa_util y la misma respuesta. Solo cambian las lineas que arman el
-- JSON. Asi la unica variable entre uno y otro es APEX:
--
--   GET /ords/app_demo/v1/prueba
--       JSON nativo de Oracle (JSON_OBJECT_T, viene con la base desde
--       12.2). No necesita APEX. Es el criterio de aceptacion del
--       build: 349 / 1000.
--
--   GET /ords/app_demo/v1/prueba-apex
--       apex_json, como los endpoints institucionales de Gedo. SIN APEX
--       falla con
--       PLS-00201: identifier 'APEX_JSON.OPEN_OBJECT' must be declared.
--       CON APEX responde 200.
--
-- Respuesta de los dos cuando funcionan:
--   {"data":{"comunas":349,"personas":1000},"status":"OK"}
--
-- Reejecutable: DEFINE_MODULE reemplaza el modulo si ya existe.
-- =====================================================================

SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE
SPOOL rest_app_demo.log

BEGIN
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_schema              => 'APP_DEMO',
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'app_demo',
      -- Endpoints anonimos: base local y descartable, igual que las
      -- passwords en claro del .env. NO exponer este puerto a la red.
      p_auto_rest_auth      => FALSE);

  ORDS.DEFINE_MODULE(
      p_module_name    => 'demo.v1',
      p_base_path      => '/v1/',
      p_items_per_page => 0,
      p_status         => 'PUBLISHED',
      p_comments       => 'Endpoints de prueba de la imagen Docker');

  -- 1) JSON nativo. Linea por linea es el mismo bloque que el de abajo:
  --    open_object -> JSON_OBJECT_T(), write -> put, y al final se
  --    imprime con htp.p, que es lo que apex_json hace por dentro.
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'demo.v1',
      p_pattern        => 'prueba');
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'demo.v1',
      p_pattern        => 'prueba',
      p_method         => 'GET',
      p_source_type    => ORDS.source_type_plsql,
      p_items_per_page => 0,
      p_source         =>
'DECLARE
    l_comunas  NUMBER := APP_DEMO.PKG_PRUEBA.contar_comunas;
    l_personas NUMBER := APP_DEMO.PKG_PRUEBA.contar_personas;
    l_resp     JSON_OBJECT_T := JSON_OBJECT_T();
    l_data     JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
    owa_util.status_line(200, '''', FALSE);
    owa_util.mime_header(''application/json'', FALSE);
    owa_util.http_header_close;
    l_data.put(''comunas'',  l_comunas);
    l_data.put(''personas'', l_personas);
    l_resp.put(''data'', l_data);
    l_resp.put(''status'', ''OK'');
    htp.p(l_resp.to_string);
END;');

  -- 2) Estilo institucional, con apex_json.
  --
  -- ORDS guarda el bloque como TEXTO y lo compila recien cuando llega
  -- la peticion. Por eso este DEFINE_HANDLER funciona aunque APEX no
  -- este instalado: el error aparece al llamar al endpoint, no aca.
  -- Es el mismo comportamiento que tendria cualquier handler
  -- institucional copiado a un ORDS sin APEX.
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'demo.v1',
      p_pattern        => 'prueba-apex');
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'demo.v1',
      p_pattern        => 'prueba-apex',
      p_method         => 'GET',
      p_source_type    => ORDS.source_type_plsql,
      p_items_per_page => 0,
      p_source         =>
'DECLARE
    l_comunas  NUMBER := APP_DEMO.PKG_PRUEBA.contar_comunas;
    l_personas NUMBER := APP_DEMO.PKG_PRUEBA.contar_personas;
BEGIN
    owa_util.status_line(200, '''', FALSE);
    owa_util.mime_header(''application/json'', FALSE);
    owa_util.http_header_close;
    apex_json.open_object;
    apex_json.open_object(''data'');
    apex_json.write(''comunas'',  l_comunas);
    apex_json.write(''personas'', l_personas);
    apex_json.close_object;
    apex_json.write(''status'', ''OK'');
    apex_json.close_object;
END;');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('==> APP_DEMO habilitado en /ords/app_demo/ con 2 endpoints');
END;
/

SPOOL OFF
EXIT
