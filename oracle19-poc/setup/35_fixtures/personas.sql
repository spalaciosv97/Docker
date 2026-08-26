-- =====================================================================
-- personas.sql — 1000 personas SINTETICAS para GRL_PERSONA
--
-- NINGUN dato sale de Desarrollo. Todo se genera aca.
--
-- Motivo: la imagen que contiene esta base se distribuye y puede
-- terminar en cualquier parte. En Desarrollo las personas son reales,
-- asi que copiarlas —incluso "anonimizadas"— es un riesgo innecesario:
-- una combinacion de comuna + fecha de nacimiento + sexo suele bastar
-- para reidentificar a alguien. Generar desde cero elimina el problema.
--
-- DETERMINISTA: DBMS_RANDOM.SEED(42) hace que cada reconstruccion de la
-- imagen produzca EXACTAMENTE las mismas 1000 personas. Si los datos
-- cambiaran en cada build, ninguna prueba automatizada seria estable.
--
-- Como reconocer que son ficticias:
--   ID_PERSONA      900001 .. 901000   (rango reservado para fixtures)
--   IDENTIFICADOR   78.xxx.xxx-D       (ver nota de rango mas abajo)
--   EMAIL           ...@example.invalid  (TLD reservado por RFC 2606:
--                                         no existe ni puede existir)
--   CELULAR/FONO    +56 9 0000 ....    (prefijo no asignado)
--   ID_USUARIO_MOD  900000             (usuario ficticio)
--
-- Ejecutar como GENERALIDADES, DESPUES de 30_data (necesita las
-- referencias y las comunas cargadas).
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

SPOOL /poc/logs/fixtures.log

DECLARE
  -- --- Parametros -----------------------------------------------------
  c_cantidad    CONSTANT PLS_INTEGER := 1000;
  c_id_base     CONSTANT NUMBER := 900000;   -- los ID van de 900001 en adelante
  c_usuario_fic CONSTANT NUMBER := 900000;   -- ID_USUARIO_MOD ficticio

  -- RUT: rango alto que hoy no se asigna a personas naturales en Chile.
  -- El digito verificador SI se calcula bien (modulo 11), para que
  -- cualquier aplicacion que valide RUT los acepte y el fixture sirva
  -- para probar de verdad.
  --
  -- PENDIENTE: confirmar el rango con alguien del equipo antes de dar
  -- esto por definitivo. Cambiarlo es modificar esta sola linea.
  c_rut_base    CONSTANT NUMBER := 78000000;

  -- --- Catalogos de nombres (ficticios, combinados al azar) ------------
  TYPE t_txt IS TABLE OF VARCHAR2(40);

  l_nom_f t_txt := t_txt(
    'Camila','Valentina','Josefa','Antonia','Isidora','Martina','Florencia',
    'Catalina','Emilia','Fernanda','Javiera','Constanza','Amanda','Renata',
    'Trinidad','Agustina','Magdalena','Rosario','Elena','Paz');

  l_nom_m t_txt := t_txt(
    'Mateo','Benjamin','Vicente','Agustin','Tomas','Joaquin','Maximiliano',
    'Cristobal','Diego','Sebastian','Ignacio','Gaspar','Emiliano','Bruno',
    'Facundo','Alonso','Damian','Rodrigo','Nicolas','Andres');

  l_apellidos t_txt := t_txt(
    'Alvear','Bustamante','Carrasco','Donoso','Echeverria','Fuentealba',
    'Gallardo','Hormazabal','Irarrazabal','Jaramillo','Klein','Lagos',
    'Maldonado','Norambuena','Ossandon','Peralta','Quintana','Riquelme',
    'Sepulveda','Tapia','Urrutia','Valenzuela','Werner','Yanez','Zamorano',
    'Bravo','Cifuentes','Delgado','Espinoza','Figueroa');

  l_calles t_txt := t_txt(
    'Los Aromos','Las Acacias','El Roble','Los Copihues','Las Araucarias',
    'El Canelo','Los Maitenes','Las Camelias','El Peumo','Los Quillayes',
    'Avenida Central','Pasaje Norte','Camino del Sur','Los Alerces',
    'El Boldo');

  -- --- IDs de referencia (se buscan, no se hardcodean) ----------------
  TYPE t_num IS TABLE OF NUMBER;
  l_sexos      t_num := t_num();
  l_generos    t_num := t_num();
  l_est_civil  t_num := t_num();
  l_tipos_dir  t_num := t_num();
  l_comuna     t_num := t_num();
  l_region     t_num := t_num();

  l_tipo_rut   NUMBER;
  l_chile      NUMBER;

  l_dirs       PLS_INTEGER := 0;

  -- --- Digito verificador de RUT (modulo 11) --------------------------
  FUNCTION dv(p_rut IN NUMBER) RETURN VARCHAR2 IS
    l_suma  NUMBER := 0;
    l_mult  NUMBER := 2;
    l_resto NUMBER := p_rut;
    l_dv    NUMBER;
  BEGIN
    WHILE l_resto > 0 LOOP
      l_suma  := l_suma + MOD(l_resto, 10) * l_mult;
      l_resto := TRUNC(l_resto / 10);
      l_mult  := CASE WHEN l_mult = 7 THEN 2 ELSE l_mult + 1 END;
    END LOOP;
    l_dv := 11 - MOD(l_suma, 11);
    RETURN CASE l_dv WHEN 11 THEN '0' WHEN 10 THEN 'K' ELSE TO_CHAR(l_dv) END;
  END dv;

  -- Entero pseudo-aleatorio en [p_lo, p_hi]. Con la semilla fija, la
  -- secuencia es siempre la misma.
  FUNCTION rnd(p_lo IN PLS_INTEGER, p_hi IN PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN
    RETURN TRUNC(DBMS_RANDOM.VALUE(p_lo, p_hi + 1));
  END rnd;

  -- Busca un item de referencia por nombre; si no lo encuentra, toma el
  -- primero de esa referencia. Evita depender de IDs magicos.
  FUNCTION item_por_nombre(p_ref IN NUMBER, p_like IN VARCHAR2)
    RETURN NUMBER IS
    l_id NUMBER;
  BEGIN
    SELECT id_item INTO l_id FROM (
      SELECT id_item FROM grl_referencia_item
       WHERE id_referencia = p_ref AND UPPER(nombre) LIKE p_like
       ORDER BY id_item)
     WHERE ROWNUM = 1;
    RETURN l_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT id_item INTO l_id FROM (
          SELECT id_item FROM grl_referencia_item
           WHERE id_referencia = p_ref ORDER BY id_item)
         WHERE ROWNUM = 1;
        RETURN l_id;
      EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
      END;
  END item_por_nombre;

BEGIN
  -- Semilla fija: sin esto el fixture cambia en cada build.
  DBMS_RANDOM.SEED(42);

  -- Idempotente: si ya se cargo, se rehace desde cero.
  DELETE FROM grl_persona_direccion    WHERE id_persona > c_id_base;
  DELETE FROM grl_direccion            WHERE id_usuario_mod = c_usuario_fic;
  DELETE FROM grl_persona_dato_personal WHERE id_persona > c_id_base;
  DELETE FROM grl_persona              WHERE id_persona > c_id_base;

  -- --- Cargar catalogos desde las referencias reales ------------------
  -- 26=sexos  22=generos  20=estados civiles  25=tipos de direccion
  -- 23=tipos de identificador  24=paises
  SELECT id_item BULK COLLECT INTO l_sexos
    FROM grl_referencia_item WHERE id_referencia = 26 ORDER BY id_item;
  SELECT id_item BULK COLLECT INTO l_generos
    FROM grl_referencia_item WHERE id_referencia = 22 ORDER BY id_item;
  SELECT id_item BULK COLLECT INTO l_est_civil
    FROM grl_referencia_item WHERE id_referencia = 20 ORDER BY id_item;
  SELECT id_item BULK COLLECT INTO l_tipos_dir
    FROM grl_referencia_item WHERE id_referencia = 25 ORDER BY id_item;

  l_tipo_rut := item_por_nombre(23, '%RUT%');
  l_chile    := item_por_nombre(24, '%CHILE%');

  -- Comunas reales (349) con su region, desde la vista institucional.
  SELECT id_comuna, id_region BULK COLLECT INTO l_comuna, l_region
    FROM grl_regiones_vw ORDER BY id_comuna;

  DBMS_OUTPUT.PUT_LINE('Catalogos: sexos=' || l_sexos.COUNT
    || ' generos=' || l_generos.COUNT
    || ' est_civil=' || l_est_civil.COUNT
    || ' tipos_dir=' || l_tipos_dir.COUNT
    || ' comunas=' || l_comuna.COUNT);

  IF l_comuna.COUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20100,
      'No hay comunas cargadas. Este script va DESPUES de 30_data.');
  END IF;

  -- --- Generar las personas -------------------------------------------
  FOR i IN 1 .. c_cantidad LOOP
    DECLARE
      l_id       NUMBER       := c_id_base + i;
      l_rut      NUMBER       := c_rut_base + i;
      l_es_mujer BOOLEAN      := MOD(i, 2) = 0;
      l_nombre   VARCHAR2(40);
      l_ape1     VARCHAR2(25) := l_apellidos(rnd(1, l_apellidos.COUNT));
      l_ape2     VARCHAR2(25) := l_apellidos(rnd(1, l_apellidos.COUNT));
      l_idx      PLS_INTEGER;
      l_id_dir   NUMBER;
      -- Todo lo que va al INSERT se calcula ANTES, en PL/SQL puro.
      -- Dentro de una sentencia SQL no se puede usar un BOOLEAN de
      -- PL/SQL ni metodos de coleccion como .COUNT: Oracle responde
      -- ORA-00920 / ORA-06550 y no es obvio por que.
      l_id_sexo   NUMBER;
      l_id_genero NUMBER;
      l_id_estciv NUMBER;
      l_id_tipdir NUMBER;
      l_discap    VARCHAR2(1);
      l_fnac      DATE;
      -- Tampoco se puede llamar a dv() dentro del INSERT: una funcion
      -- local de PL/SQL no es visible desde SQL (PLS-00231).
      l_ident     VARCHAR2(20);
    BEGIN
      IF l_es_mujer THEN
        l_nombre := l_nom_f(rnd(1, l_nom_f.COUNT));
      ELSE
        l_nombre := l_nom_m(rnd(1, l_nom_m.COUNT));
      END IF;

      IF l_sexos.COUNT > 0 THEN
        -- Primer item = femenino, segundo = masculino, segun el orden
        -- de la referencia. Si solo hubiera uno, se usa ese.
        l_id_sexo := l_sexos(CASE WHEN l_es_mujer THEN 1
                                  ELSE LEAST(2, l_sexos.COUNT) END);
      END IF;

      IF l_generos.COUNT   > 0 THEN l_id_genero := l_generos(rnd(1, l_generos.COUNT));     END IF;
      IF l_est_civil.COUNT > 0 THEN l_id_estciv := l_est_civil(rnd(1, l_est_civil.COUNT)); END IF;
      IF l_tipos_dir.COUNT > 0 THEN l_id_tipdir := l_tipos_dir(rnd(1, l_tipos_dir.COUNT)); END IF;

      l_discap := CASE WHEN rnd(1, 100) <= 5 THEN 'S' ELSE 'N' END;
      -- nacidos entre 1960 y 2005
      l_fnac   := TO_DATE('01-01-1960','DD-MM-YYYY') + rnd(0, 16800);
      l_ident  := TO_CHAR(l_rut) || '-' || dv(l_rut);

      -- ID_PERSONA se asigna explicitamente: la tabla no tiene identity
      -- ni trigger que lo haga (ver la nota para QA en el README).
      INSERT INTO grl_persona (
        id_persona, identificador, id_tipo_id, nombres,
        primer_apellido, segundo_apellido, fecha_nac,
        id_sexo, id_genero, con_discapacidad, id_nacionalidad,
        fallecido, id_usuario_mod, fec_ult_mod)
      VALUES (
        l_id,
        l_ident,
        l_tipo_rut,
        l_nombre,
        l_ape1,
        l_ape2,
        l_fnac,
        l_id_sexo,
        l_id_genero,
        l_discap,
        l_chile,
        'N',
        c_usuario_fic,
        SYSDATE);

      -- Datos de contacto. El dominio .invalid esta reservado por RFC
      -- 2606: no existe ni puede existir, asi que es imposible enviarle
      -- un correo a una de estas personas por accidente.
      INSERT INTO grl_persona_dato_personal (
        id_persona, celular, fono, email, fec_ult_act,
        id_estado_civil, id_usuario_mod, fec_ult_mod)
      VALUES (
        l_id,
        '+56 9 0000 ' || LPAD(TO_CHAR(MOD(i, 10000)), 4, '0'),
        '+56 2 0000 ' || LPAD(TO_CHAR(MOD(i * 7, 10000)), 4, '0'),
        LOWER(l_nombre) || '.' || LOWER(l_ape1) || i || '@example.invalid',
        SYSDATE,
        l_id_estciv,
        c_usuario_fic,
        SYSDATE);

      -- Direccion en una comuna real. El trigger INSERT_ID_DIRECCION
      -- asigna el ID_DIRECCION desde GRL_DIRECCIONES_SEQ.
      l_idx := rnd(1, l_comuna.COUNT);

      DECLARE
        l_calle  VARCHAR2(100) := l_calles(rnd(1, l_calles.COUNT));
        l_numero VARCHAR2(10)  := TO_CHAR(rnd(100, 9999));
        l_com    NUMBER        := l_comuna(l_idx);
        l_reg    NUMBER        := l_region(l_idx);
      BEGIN
        INSERT INTO grl_direccion (
          calle, numero, id_comuna, id_region, ciudad,
          id_pais, fec_ult_act, id_usuario_mod)
        VALUES (
          l_calle, l_numero, l_com, l_reg, NULL,
          l_chile, SYSDATE, c_usuario_fic)
        RETURNING id_direccion INTO l_id_dir;
      END;

      INSERT INTO grl_persona_direccion (id_persona, id_direccion, id_tipo)
      VALUES (l_id, l_id_dir, l_id_tipdir);

      l_dirs := l_dirs + 1;
    END;
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Personas sinteticas creadas: ' || c_cantidad);
  DBMS_OUTPUT.PUT_LINE('Direcciones creadas:         ' || l_dirs);
END;
/

PROMPT
PROMPT === Muestra del fixture =============================================
COLUMN identificador FORMAT A14
COLUMN nombre        FORMAT A38
COLUMN email         FORMAT A38
COLUMN comuna        FORMAT A20

SELECT p.id_persona,
       p.identificador,
       p.nombres || ' ' || p.primer_apellido || ' ' || p.segundo_apellido AS nombre,
       d.email,
       c.comuna
  FROM grl_persona p
  JOIN grl_persona_dato_personal d ON d.id_persona = p.id_persona
  LEFT JOIN grl_persona_direccion pd ON pd.id_persona = p.id_persona
  LEFT JOIN grl_direccion dir ON dir.id_direccion = pd.id_direccion
  LEFT JOIN grl_comunas_vw c ON c.id_comuna = dir.id_comuna
 WHERE p.id_persona > 900000
 ORDER BY p.id_persona
 FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT === Conteos =========================================================
SELECT 'GRL_PERSONA'               AS tabla, COUNT(*) AS filas FROM grl_persona
UNION ALL
SELECT 'GRL_PERSONA_DATO_PERSONAL',         COUNT(*) FROM grl_persona_dato_personal
UNION ALL
SELECT 'GRL_PERSONA_DIRECCION',             COUNT(*) FROM grl_persona_direccion
UNION ALL
SELECT 'GRL_DIRECCION',                     COUNT(*) FROM grl_direccion;

SPOOL OFF
