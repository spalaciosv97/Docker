-- =====================================================================
-- 02_roles_stub.sql — Usuarios "stub" para que los GRANT no fallen
--
-- El DDL que exporto QA trae GRANT ... TO <esquema institucional> en
-- casi cada tabla y package. En Docker esos esquemas no existen, asi
-- que cada GRANT abortaria con ORA-01917 (user or role does not exist)
-- y ensuciaria el log con cientos de errores irrelevantes.
--
-- Se crean vacios, SIN privilegios y SIN quota: solo existen para que
-- el GRANT tenga a quien apuntar. No pueden conectarse ni hacer nada.
--
-- AUDITOR y SIGESUSTIC NO estan aqui: esos si llevan tablas reales y
-- se crean en 03_auditor_min.sql y 04_sigesustic_min.sql.
-- =====================================================================

DECLARE
  TYPE t_names IS TABLE OF VARCHAR2(30);
  l_users t_names := t_names(
    'APPGRL', 'APPLOG', 'APPSRP', 'APPSSGU', 'APPSTK',
    'CALIDAD', 'DACIDTIC', 'GESTPERSDTIC',
    'NOTIFICACIONESAPPS', 'NOTIFICACIONESTIC',
    'SECRETARIAGRALDTIC', 'SIACPAAPPS', 'SIACPATESTAPPS', 'SIACPATESTTIC',
    'SIEVAUTIC', 'SIGETIC', 'SIREPER'
  );
  l_exists NUMBER;
BEGIN
  FOR i IN 1 .. l_users.COUNT LOOP
    SELECT COUNT(*) INTO l_exists FROM dba_users WHERE username = l_users(i);
    IF l_exists = 0 THEN
      EXECUTE IMMEDIATE
        'CREATE USER ' || l_users(i) || ' IDENTIFIED BY "&STUB_PWD."'
        || ' ACCOUNT LOCK';
      DBMS_OUTPUT.PUT_LINE('stub creado: ' || l_users(i));
    ELSE
      DBMS_OUTPUT.PUT_LINE('stub ya existia: ' || l_users(i));
    END IF;
  END LOOP;
END;
/

PROMPT ==> Stubs de grantees listos
