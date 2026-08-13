--------------------------------------------------------
--  DDL for Trigger TRG_VALIDA_GRL_PARAMETRO_FK
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "GENERALIDADES"."TRG_VALIDA_GRL_PARAMETRO_FK" BEFORE INSERT OR UPDATE ON GRL_PARAMETRO
FOR EACH ROW
DECLARE
    v_dummy NUMBER;
    ----------------------------------------------------------------
    -- Valida existencia en cualquier tabla
    ----------------------------------------------------------------
    PROCEDURE valida_existencia (
        p_sql      VARCHAR2,
        p_valor    NUMBER,
        p_campo    VARCHAR2
    ) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql
        INTO v_dummy
        USING p_valor;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF INSERTING THEN
                RAISE_APPLICATION_ERROR(-20005, 'Valor inválido para ' || p_campo || ' en INSERT');
            ELSE
                RAISE_APPLICATION_ERROR(-20006, 'Valor inválido para ' || p_campo || ' en UPDATE');
            END IF;
    END valida_existencia;

BEGIN
    ---------------------------------------------------------
    -- Optimización:
    -- si no cambian los campos, no valida
    ---------------------------------------------------------
    IF UPDATING THEN

        IF NVL(:OLD.ID_SISTEMA, -1) = NVL(:NEW.ID_SISTEMA, -1)
        AND NVL(:OLD.ID_APLICACION, -1) = NVL(:NEW.ID_APLICACION, -1)
        AND NVL(:OLD.ID_USUARIO, -1) = NVL(:NEW.ID_USUARIO, -1)
        THEN
            RETURN;
        END IF;

    END IF;
    ---------------------------------------------------------
    -- Validar sistema
    ---------------------------------------------------------
    valida_existencia(
        'SELECT 1 FROM SIGESUSTIC.SGU_SISTEMA WHERE SIS_ID = :1',
        :NEW.ID_SISTEMA,
        'ID_SISTEMA'
    );
    ---------------------------------------------------------
    -- Validar aplicación
    ---------------------------------------------------------
    valida_existencia(
        'SELECT 1 FROM SIGESUSTIC.SGU_APLICACION WHERE APP_ID = :1',
        :NEW.ID_APLICACION,
        'ID_APLICACION'
    );
    ---------------------------------------------------------
    -- Validar usuario
    ---------------------------------------------------------
    valida_existencia(
        'SELECT 1 FROM SIGESUSTIC.SGU_USUARIO WHERE USR_ID = :1',
        :NEW.ID_USUARIO,
        'ID_USUARIO'
    );

END;
ALTER TRIGGER "GENERALIDADES"."TRG_VALIDA_GRL_PARAMETRO_FK" ENABLE
