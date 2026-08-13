--------------------------------------------------------
--  DDL for Trigger TRG_VALIDA_GRL_PARAMETRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "GENERALIDADES"."TRG_VALIDA_GRL_PARAMETRO" BEFORE INSERT OR UPDATE ON GRL_PARAMETRO 
FOR EACH ROW
DECLARE
    v_dummy NUMBER;
    -- función local para validar catálogo
    PROCEDURE valida_valor (
        p_referencia NUMBER,
        p_valor      NUMBER,
        p_campo      VARCHAR2
    ) IS
    BEGIN
        SELECT 1
        INTO v_dummy
        FROM GRL_REFERENCIA_ITEM
        WHERE id_item = p_valor
        AND id_referencia = p_referencia
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF INSERTING THEN
                RAISE_APPLICATION_ERROR(-20005, 'Valor invalido para ' || p_campo || ' en INSERT');
            ELSE
                RAISE_APPLICATION_ERROR(-20006, 'Valor invalido para ' || p_campo || ' en UPDATE');
            END IF;
    END valida_valor;

BEGIN
    -- optimización: si es update y no cambió nada, no validar
    IF UPDATING THEN
        IF :OLD.id_tipo = :NEW.id_tipo
           AND :OLD.id_tipo_dato = :NEW.id_tipo_dato
           AND :OLD.id_estado = :NEW.id_estado THEN
           RETURN;
        END IF;
    END IF;

    -- validar tipo
    valida_valor(10, :NEW.id_tipo, 'ID_TIPO');
    -- validar tipo dato
    valida_valor(36, :NEW.id_tipo_dato, 'ID_TIPO_DATO');
    -- validar estado
    valida_valor(15, :NEW.id_estado, 'ID_ESTADO');
END;
ALTER TRIGGER "GENERALIDADES"."TRG_VALIDA_GRL_PARAMETRO" ENABLE
