# PoC — Oracle 19c SE2 + GENERALIDADES en Docker

Instala el esquema institucional `GENERALIDADES` dentro de un Oracle 19c
en Docker, **sin depender de DEV, QA, VPN ni DB Links**, para que un
desarrollador pueda después agregar su propio esquema encima.

Contexto completo del proyecto: [`../CONTEXTO_ORACLE_DOCKER_POC.md`](../CONTEXTO_ORACLE_DOCKER_POC.md).

---

## Cómo se ejecuta

```bash
cd oracle19-poc

# 1. Levantar el LAB (volumen descartable, puerto 1522)
docker compose -p oracle19-lab -f compose.lab.yaml up -d

# 2. Esperar a que Oracle termine de crear la base (primera vez: ~15 min)
docker compose -p oracle19-lab -f compose.lab.yaml logs -f
#    ...esperar "DATABASE IS READY TO USE!", luego Ctrl-C

# 3. Instalar GENERALIDADES
docker exec -it oracle19-lab bash /poc/install.sh

# 4. Revisar los logs (quedan en ./logs/ del host)
cat logs/validate_generalidades.log
```

**Criterio de éxito:** la sección 2 de `validate_generalidades.log`
(objetos inválidos) debe estar vacía.

Después, la prueba que realmente demuestra la PoC:

```bash
docker exec -it oracle19-lab bash -c \
  'NLS_LANG=.AL32UTF8 sqlplus -S "sys/Oracle_Poc_2026@localhost:1521/DEMOCDB as sysdba" \
   @/poc/setup/99_validation/prueba_funcional.sql'
```

Crea `APP_DEMO` y un package que consume `PKG_UTILIDADES`, `PKG_LOG` y
`GRL_COMUNAS_VW` — es decir, un esquema externo usando de verdad las
librerías institucionales.

Conexión desde DataGrip: `127.0.0.1:1522`, Service Name `DEMOPDB`,
usuario `GENERALIDADES` / `Grl_Poc_2026`.

---

## Por qué existe el LAB separado

El `oracle19-poc` original (puerto 1521) y su volumen **no se tocan**.
Este LAB usa otro nombre de proyecto, otro volumen y otro puerto, así
que si la instalación queda a medias se destruye solo el LAB:

```bash
docker volume ls | grep oracle19          # confirmar cuál es cuál
docker compose -p oracle19-lab -f compose.lab.yaml down -v
```

Nunca correr `down -v` sin verificar antes que el volumen apuntado sea
`oracle19-lab_oracle19_lab_data`.

---

## Estructura

```
oracle19-poc/
├── compose.lab.yaml            entorno descartable (puerto 1522)
├── install.sh                  orquestador, corre dentro del contenedor
├── logs/                        salida de cada paso (bind mount)
└── setup/
    ├── 01_pre/                 lo que tiene que existir ANTES
    │   ├── 00_env.sql             variables + ALTER SESSION SET CONTAINER
    │   ├── 01_tablespaces.sql     GENERALIDADES_DATA / _INDEX
    │   ├── 02_roles_stub.sql      16 usuarios vacíos, para que los GRANT no fallen
    │   ├── 03_auditor_min.sql     AUDITOR.LOG_SYSTEM + secuencia
    │   ├── 04_sigesustic_min.sql  SGU_SISTEMA / SGU_APLICACION / SGU_USUARIO
    │   └── 05_generalidades_user.sql
    ├── 10_generalidades/       el esquema en sí
    │   ├── MASTER_GRL_DOCKER.sql  orquestador, 80 referencias
    │   ├── no_versionables/       75 archivos de QA (tablas, índices, triggers…)
    │   ├── versionables/          23 specs sueltos de QA (referencia; el MASTER usa packages/)
    │   ├── packages/              PACKAGES.sql + PACKAGE_BODIES.sql ya limpios
    │   ├── extra/                 los 2 objetos que faltaban en la entrega
    │   └── VIEWS.sql              13 vistas
    ├── 20_post/                sinónimos públicos (requiere SYS)
    ├── 30_data/                datos maestros, reemplazables
    ├── 40_recompile/           recompilación final, después de los sinónimos
    └── 99_validation/          validación + prueba funcional
```

El orden de las carpetas es el orden de ejecución, y **no es arbitrario**
en dos puntos:

- `GENERALIDADES` se crea en `01_pre/02`, **antes** que `AUDITOR` y
  `SIGESUSTIC`, porque esos dos le hacen `GRANT`. Al revés, los `GRANT`
  fallan con `ORA-01917` y `PKG_LOG` queda `INVALID` (usa `%TYPE` contra
  `AUDITOR.LOG_SYSTEM`), arrastrando a los 20 bodies que dependen de él.
- `40_recompile` existe porque varios bodies llaman a los packages por
  sus **sinónimos públicos** (`CONST`, `UTILIDADES`, `VALIDATOR`), que
  requieren SYS y por eso se crean recién en `20_post`. Sin esa pasada
  final quedan 19 bodies `INVALID`.

---

## Qué se cambió respecto a lo que entregó QA

Los archivos originales en [`../GENERALIDADES/`](../GENERALIDADES/) **no
se modificaron**. Todo lo de abajo son cambios en la copia bajo
`setup/`, para poder recibir una nueva entrega de QA sin perderlos.

### Bugs encontrados en la entrega

| # | Problema | Efecto si no se corrige |
|---|---|---|
| 1 | `MASTER GRL.sql` define `BASE_PATH_NO_VERSIONABLES` pero referencia `&BASE_PATH_NO_VERSIONALES.` (falta la `B`) | SQL\*Plus pide el valor por prompt en las 74 líneas; el script no corre solo |
| 2 | Rutas absolutas `C:\Users\Camilo Donoso\...` | No existen dentro del contenedor Linux |
| 3 | **67 de 75 archivos sin ningún `;`** al final de sus sentencias | SQL\*Plus no ejecuta nada. Se agregaron 545 terminadores |
| 4 | **5 triggers y `TO_FLOAT_SYN` sin el terminador `/`** | SQL\*Plus nunca envía el bloque: los 6 objetos **no se crean** |
| 5 | **19 de 98 archivos en CP1252**, el resto en UTF-8 | Con `NLS_LANG=.AL32UTF8` los acentos entran corruptos de forma permanente |
| 6 | `SEQUENCES.sql` va después de los triggers, que usan `SEC_ARCHIVOS_*.NEXTVAL` | Los triggers se crean `INVALID` |
| 7 | El índice Oracle Text sobre JSON va antes del `CHECK (metadata IS JSON)` que necesita | `DRG-10720`; el índice no se crea |
| 8 | **`GRANT ALTER TABLE` y `SELECT SEQUENCE` no son privilegios de Oracle** | El `GRANT` falla completo y `GENERALIDADES` se queda sin `CREATE VIEW` |
| 9 | Sinónimos públicos con `/` sueltos tras sentencias ya terminadas en `;` | Reejecuta la anterior → `ORA-00955` espurios |
| 10 | El MASTER no carga `VIEWS.sql`, `TO_FLOAT_SYN.sql` ni los bodies | Objetos que el código usa nunca se crean |

Todos corregidos en la copia.

El nº 8 merece explicación porque es el más engañoso: Oracle evalúa cada
`GRANT` como una sola sentencia, así que un privilegio inexistente en la
lista tumba también a los válidos que lo acompañan. Se manifestaba como
`ORA-01031` al crear las vistas, sin ninguna pista del origen real.

### Una inconsistencia pendiente de confirmar con QA

`PKG_REFERENCIA` usa `GRL_REFERENCIA.FECHA_CREACION`, columna que **no
existe** — la tabla tiene `FECHA_REG`, y `FECHA_CREACION` no aparece en
ningún DDL de la entrega. Se aplicó el reemplazo en nuestra copia de
`PACKAGE_BODIES.sql`, con un comentario que lo marca.

**Preguntar al compañero si la desactualizada es la tabla o el package.**

### Objetos que faltaban y se reconstruyeron desde Desarrollo

- `GRL_PARAMETRO_ROL` (tabla) — sin PK ni FK, igual que en DEV.
- `GRL_COMUNAS_VW` (vista).
- `AUDITOR.LOG_SYSTEM` + `SEQ_LOG_SYSTEM_LOG_ID`.
- `SIGESUSTIC.SGU_SISTEMA` / `SGU_APLICACION` / `SGU_USUARIO`.

### Objetos que se excluyeron

13 packages de testing (`PKG_TEST_*`, `PKG_EXAMPLE`, `PKG_COMPARADOR`)
que QA confirmó que se le pasaron por error. Se verificó que forman un
bloque cerrado: `PKG_COMPARADOR` solo lo usa `PKG_EXAMPLE`, y a
`PKG_EXAMPLE` solo lo usa `PKG_TEST_EXAMPLE`. Ningún package real
depende de ellos.

Quedan 23 specs + 22 bodies (`PKG_GRL_CONFIG` no tiene body: es solo
constantes).

### Adaptaciones a Docker

- **Datafiles sin ruta**, usando OMF (`DB_CREATE_FILE_DEST`). QA usa
  `/u02/app/oracle/oradata/CDBUNAP/pdbunap/`, que no existe acá. Con OMF
  el mismo script sirve en ambos lados.
- **`AUTOEXTEND` agregado**: QA los crea con 50M fijos y el esquema no
  cabe.
- **Todo dentro del PDB** (`ALTER SESSION SET CONTAINER = DEMOPDB`). En
  `CDB$ROOT` Oracle exigiría el prefijo `C##` en los nombres de usuario.
- **Carpetas sin espacios** (`No versionables` → `no_versionables`): el
  `@` de SQL\*Plus se lleva mal con rutas con espacios.
- **`@@` en vez de `@`** en el MASTER, para que las rutas se resuelvan
  relativas al script y no al directorio de trabajo.

---

## Cosas que hay que saber

**`NLS_LANG=.AL32UTF8` no es opcional.** `install.sh` lo exporta. Sin
eso, sqlplus asume el charset del SO y mete los acentos corruptos a la
base — y ya no se arreglan sin recargar los datos.

**Grants directos, no por rol.** PL/SQL ignora los privilegios
heredados de roles al compilar. Por eso `03_auditor_min.sql` hace
`GRANT ... ON AUDITOR.LOG_SYSTEM TO GENERALIDADES` directo: vía rol,
`PKG_LOG` quedaría `INVALID`.

**Las semillas de SIGESUSTIC son las que son.** `04_sigesustic_min.sql`
siembra exactamente los IDs que aparecen en los 23 INSERT de
`GRL_PARAMETRO`. Si más adelante se cargan más parámetros, hay que
ampliar esas listas o `TRG_VALIDA_GRL_PARAMETRO_FK` los rechaza con
`ORA-20005`.

**Oracle Text sí viene en la imagen** (`CONTEXT` VALID 19.0.0.0.0), así
que el índice JSON se crea sin problema. Solo hay que respetar el orden:
va después del `CHECK (metadata IS JSON)`.

**El código institucional tiene dos dependencias de entorno.** Importan
para cualquier backend que se conecte:

- `PKG_UTILIDADES.TO_FLOAT` hace `REPLACE(valor,'.',',')` y luego
  `TO_NUMBER`, así que **asume `NLS_NUMERIC_CHARACTERS = ',.'`**. Con el
  default del contenedor devuelve `NULL` en silencio.
- `PKG_LOG.INSERT_REGISTRO` exige un `LOG_ID` no nulo. El punto de
  entrada correcto es **`REGISTRA_LOG`**, que lo genera solo desde la
  secuencia de `AUDITOR`.

**`SET SERVEROUTPUT ON` va después de `ALTER SESSION SET CONTAINER`.**
Cambiar de contenedor resetea el estado PL/SQL de la sesión y desactiva
`DBMS_OUTPUT`; al revés, los `PUT_LINE` se pierden sin avisar.

**Cuidado con `PROMPT` terminado en guion.** En SQL\*Plus un `-` al
final de línea es continuación, así que `PROMPT --- titulo ---` se come
la línea siguiente. Por eso los separadores de estos scripts usan `=`.

**El conteo de objetos del contexto (§13) no es la meta.** Esos números
(40 tablas, 41 vistas, 47 packages) salieron de **Desarrollo**, que está
más sucio. La entrega es de **QA**. El criterio real es cero objetos
inválidos; el conteo se comparará contra el inventario de QA cuando el
compañero termine de depurarlo.

**Los datos son de Desarrollo.** 113 + 1203 + 23 filas. Viven aislados
en `30_data/` justamente para poder reemplazarlos por el set limpio de
QA sin tocar el resto de la instalación.

---

## Pendiente

- [ ] Correr la instalación de punta a punta y resolver los ORA- que
      salgan.
- [ ] Pedir a QA el conteo `DBA_OBJECTS` de su ambiente ya depurado.
- [ ] Reemplazar `30_data/` por el set limpio de QA cuando llegue.
- [ ] Confirmar si `GENERALIDADES` tiene sinónimos privados en QA (los 8
      del inventario venían de DEV).
- [ ] Una vez todo verde: empaquetar en `/opt/oracle/scripts/setup` para
      que la instalación corra sola al levantar el contenedor.
- [ ] Después, y por separado: subir la imagen al RU 19.31 para igualar
      el ambiente institucional.
