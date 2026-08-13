# Bitácora — PoC Oracle 19c + GENERALIDADES en Docker

> Resumen de todo lo hecho, en orden, con las decisiones y por qué se
> tomaron. Complementa a [`CONTEXTO_ORACLE_DOCKER_POC.md`](CONTEXTO_ORACLE_DOCKER_POC.md),
> que tiene el detalle técnico del ambiente.
>
> Última actualización: 12 de agosto de 2026.

---

## Qué se está probando

El jefe pidió evaluar si es viable tener un **Oracle en Docker
autónomo**, que ya venga con las librerías institucionales del esquema
`GENERALIDADES`, para que después un desarrollador agregue su propio
esquema encima.

La condición dura es que **funcione sin DEV, sin QA, sin VPN y sin DB
Links**. Si el entorno depende de conectarse a algo de la universidad,
la PoC falla su objetivo.

```
Oracle Docker
├── Oracle 19c SE2
├── GENERALIDADES            (librerías institucionales)
├── dependencias mínimas     (AUDITOR, SIGESUSTIC)
└── + SU_ESQUEMA             ← lo agrega el desarrollador
```

---

## FASE 1 — Infraestructura ✅

| Paso | Resultado |
|---|---|
| Reparar WSL 2 (daba `Wsl/Service/E_UNEXPECTED`) | Ubuntu levanta, usuario `seba` |
| Docker Desktop integrado con WSL | 29.6.2, contenedores Linux |
| Construir Oracle 19c **SE2** desde `docker-images` oficial | `local/oracle19c-se2:19.3.0`, ~19 min de build, 9.5 GB |
| Crear `DEMOCDB` / `DEMOPDB` | contenedor `oracle19-poc`, puerto 1521 |
| Verificar charset | `AL32UTF8` + `AL16UTF16`, **coincide con la institucional** |
| Verificar persistencia | `docker compose down` → `up` y los datos siguen ahí |
| Conectar DataGrip | OK vía Service Name `DEMOPDB` |

**Se usó SE2, no Enterprise.** El RPM que Oracle publica es Enterprise
Edition; hubo que bajar `LINUX.X64_193000_db_home.zip` y construir con
el flag `-s` para que quedara Standard Edition 2, que es lo que usa la
universidad.

**Diferencia de versión conocida:** la PoC está en 19.3, la universidad
en 19.31. Ambos son Oracle 19c — 19.3 es la imagen base y 19.31 es un
Release Update acumulativo. Se decidió **primero demostrar que todo
funciona en 19.3** y recién después conseguir el RU con el DBA. No se
declara equivalencia con QA hasta igualar el RU.

---

## FASE 2 — GENERALIDADES

### Se descartó el DB Link

La primera idea era que el Docker leyera `GENERALIDADES` de Desarrollo
por DB Link. **El jefe lo descartó**: eso mantendría la dependencia de
la red institucional, que es justo lo que se quiere eliminar.

### Se descartó (por ahora) Data Pump

`expdp`/`impdp` era la opción obvia, pero el compañero de QA ofreció los
scripts SQL con los que se crea `GENERALIDADES` en QA. Eso es mejor para
esta PoC: deja la instalación **versionada como código** y reproducible,
en vez de un `.dmp` binario opaco.

### La entrega de QA llegó en partes

| Fecha | Qué llegó |
|---|---|
| 10-11 ago | Carpeta `GENERALIDADES/` — `MASTER GRL.sql` + 98 archivos (`No versionables/`, `Versionables/`) |
| 11 ago | `PACKAGES.sql` (36 specs) y `PACKAGE_BODIES.sql` (35 bodies) — **faltaban en la primera entrega** |
| 11 ago | `VIEWS.sql` (13 vistas) |
| 11 ago | Script de `CREATE USER` + tablespaces |
| 12 ago | Datos maestros: 113 + 1203 + 23 INSERTs |
| 12 ago | Estructura de `AUDITOR` y `SIGESUSTIC` sacada del diccionario de DEV |

---

## Los enredos que hubo, y cómo se resolvieron

### 1. El inventario de objetos era de Desarrollo, no de QA

El conteo del contexto (40 tablas, 41 vistas, 47 packages…) se sacó de
**Desarrollo**. La entrega es de **QA, que está más limpio** y que el
compañero sigue depurando.

**Consecuencia práctica:** perseguir esos números llevaría a instalar
objetos muertos de DEV. Se cambió el criterio de validación a **cero
objetos inválidos**, y el conteo queda para comparar cuando QA entregue
su inventario depurado.

### 2. Faltaban los package bodies

`Versionables/` traía 23 archivos con **solo las especificaciones**, ni
un body. Sin bodies, `GENERALIDADES` habría quedado con 45 objetos
inválidos y ninguna librería ejecutable — o sea, la PoC no demostraba
nada. El compañero confirmó que se le habían pasado y los envió.

### 3. Venían 13 packages de testing por error

`PKG_EXAMPLE`, `PKG_COMPARADOR` y 11 `PKG_TEST_*`. QA confirmó que había
que borrarlos. Se verificó que forman un **bloque cerrado**
(`PKG_COMPARADOR` ← `PKG_EXAMPLE` ← `PKG_TEST_EXAMPLE`) y que ningún
package real depende de ellos, así que salieron sin romper nada.

Quedan 23 specs + 22 bodies. `PKG_GRL_CONFIG` no tiene body porque es
solo constantes.

### 4. Faltaban 4 objetos que el código usa

Cruzando qué referencian los bodies contra el DDL entregado aparecieron
`GRL_PARAMETRO_ROL`, `GRL_COMUNAS_VW`, `GRL_ESTADO_ITEM_VW` y
`GRL_OBJETO_LISTA_VW`. Los dos últimos llegaron en `VIEWS.sql`; los
otros dos se reconstruyeron desde el diccionario de Desarrollo.

Detalle: `GRL_PARAMETRO_ROL` **no tiene PK ni FK** en DEV. Se replicó
así a propósito — agregarle una PK "obvia" podría rechazar filas que el
código sí inserta.

### 5. Las dependencias externas eran menos de lo que parecía

Se pensaba traer el esquema `AUDITOR` completo. Un barrido sobre todo el
código mostró que `GENERALIDADES` usa **solo dos objetos**:
`AUDITOR.LOG_SYSTEM` (52 usos) y `AUDITOR.SEQ_LOG_SYSTEM_LOG_ID` (1).
Ningún package.

De `SIGESUSTIC` solo tres tablas: `SGU_SISTEMA`, `SGU_APLICACION`,
`SGU_USUARIO`.

Como no había privilegio de catálogo para `DBMS_METADATA`, se
reconstruyeron desde `ALL_TAB_COLUMNS`.

### 6. Nueve bugs en los scripts que habrían roto la instalación

Los primeros aparecieron al procesar los archivos; el resto, recién al
ejecutarlos contra Oracle.

| # | Bug | Efecto |
|---|---|---|
| 1 | Typo `BASE_PATH_NO_VERSIONABLES` vs `&BASE_PATH_NO_VERSIONALES.` | SQL\*Plus pide el valor por prompt en las 74 líneas |
| 2 | Rutas absolutas `C:\Users\Camilo Donoso\...` | No existen en el contenedor Linux |
| 3 | **67 de 75 archivos sin ningún `;`** | SQL\*Plus no ejecuta nada. **El bug más grave** |
| 4 | 5 triggers y `TO_FLOAT_SYN` sin el terminador `/` | Los 6 objetos no se crean, sin error evidente |
| 5 | **19 de 98 archivos en CP1252**, el resto UTF-8 | Con `NLS_LANG=.AL32UTF8` los acentos entran corruptos de forma permanente |
| 6 | `SEQUENCES.sql` después de los triggers que las usan | Los triggers se crean `INVALID` |
| 7 | El índice Oracle Text sobre JSON va **antes** del `CHECK (metadata IS JSON)` que necesita | `DRG-10720`, el índice no se crea |
| 8 | **`GRANT ALTER TABLE` y `SELECT SEQUENCE` no son privilegios de Oracle** | El GRANT falla completo, `GENERALIDADES` se queda sin `CREATE VIEW`, y caen las 14 vistas + ~100 grants sobre ellas |
| 9 | Sinónimos públicos con `/` sueltos tras `;` | Reejecuta la sentencia anterior → `ORA-00955` espurios |

El nº 8 fue el más engañoso: Oracle evalúa cada `GRANT` como una sola
sentencia, así que un privilegio inexistente en la lista tumba también a
los válidos que lo acompañan. Se manifestaba como `ORA-01031` al crear
vistas, sin ninguna pista del origen.

**Todos corregidos en la copia Docker. Los originales de QA no se
tocaron**, para poder recibir una entrega nueva sin perder los arreglos.

### 7bis. Una inconsistencia que hay que confirmar con QA

`PKG_REFERENCIA` inserta y lee `GRL_REFERENCIA.FECHA_CREACION`, pero esa
columna **no existe**: la tabla tiene `FECHA_REG`. `FECHA_CREACION` no
aparece en ningún DDL de la entrega, solo en ese package body.

Se aplicó el reemplazo `FECHA_CREACION` → `FECHA_REG` en nuestra copia,
marcado con un comentario. **Pendiente preguntarle al compañero si la
desactualizada es la tabla o el package.**

### 8. Dos trampas de orden que solo aparecen instalando desde cero

Estas son las más difíciles de encontrar, porque **una reinstalación
sobre una base ya usada las esconde**:

**Los `GRANT` a `GENERALIDADES` iban antes de crearlo.** `03_auditor_min`
le otorgaba permisos sobre `LOG_SYSTEM`, pero el usuario se creaba en
`05`. Los `GRANT` fallaban con `ORA-01917`, y como `PKG_LOG` usa `%TYPE`
contra esa tabla, quedaba `INVALID` y arrastraba a los 20 bodies que
dependen de él. Se reordenó: `GENERALIDADES` ahora va segundo.

**Varios bodies llaman a los packages por sus sinónimos públicos.**
`PKG_UTILIDADES` usa `CONST.REF_ITEM_ESTADO_ACTIVO`, `PKG_VALIDATOR` usa
`UTILIDADES.VALIDATE_PERSONA`, etc. Pero `CREATE PUBLIC SYNONYM` exige
SYS, así que los sinónimos se crean después del MASTER — cuando los
bodies ya intentaron compilar. Quedaban 19 `INVALID`.

Esto no se veía al reinstalar porque **los sinónimos públicos sobreviven
al `DROP USER`**. Solo apareció al destruir el volumen y empezar de
cero. Se agregó el paso `40_recompile`, que corre después de los
sinónimos.

Lección de método: contar errores `ORA-` en los logs no era criterio
suficiente — un package body que no compila queda `INVALID` sin emitir
ninguna línea `ORA-`. El `install.sh` ahora le pregunta a la base
directamente.

### 9. Dos dependencias de entorno del código institucional

Aparecieron al correr la prueba funcional, y conviene que las sepa
cualquiera que conecte un backend:

- **`PKG_UTILIDADES.TO_FLOAT` asume locale español.** Hace
  `REPLACE(valor,'.',',')` y luego `TO_NUMBER`, así que necesita
  `NLS_NUMERIC_CHARACTERS = ',.'`. Con el default devuelve `NULL` sin
  avisar.
- **`PKG_LOG.INSERT_REGISTRO` exige un `LOG_ID` no nulo.** El punto de
  entrada correcto para una aplicación es `REGISTRA_LOG`, que lo genera
  solo desde la secuencia de `AUDITOR`.

---

## Qué se construyó

`oracle19-poc/` — proyecto completo, versionable:

```
compose.lab.yaml      entorno descartable (puerto 1522, volumen propio)
install.sh            orquestador de los 5 pasos
setup/
  01_pre/             tablespaces, stubs, AUDITOR, SIGESUSTIC, usuario
  10_generalidades/   MASTER_GRL_DOCKER.sql + 80 archivos referenciados
  20_post/            sinónimos públicos (requiere SYS)
  30_data/            datos maestros, aislados para poder reemplazarlos
  99_validation/      validación + prueba funcional con APP_DEMO
```

### Decisiones de diseño

**Volumen descartable.** El `oracle19-poc` original y su volumen no se
tocan. El lab usa otro nombre de proyecto, otro volumen y el puerto
1522, así que un error se limpia destruyendo solo el lab.

**Datos separados del DDL.** Los INSERT viven en `30_data/` justamente
para reemplazarlos por el set limpio de QA sin rehacer la instalación.

**Usuarios stub.** El DDL de QA hace `GRANT ... TO` a 18 esquemas
institucionales que en Docker no existen. Se crean 16 usuarios vacíos y
bloqueados solo para que los `GRANT` tengan destino y no ensucien el log
con cientos de `ORA-01917`.

**Grants directos, no por rol.** PL/SQL ignora los privilegios heredados
de roles al compilar. Si el acceso a `AUDITOR.LOG_SYSTEM` fuera vía rol,
`PKG_LOG` quedaría `INVALID`.

**OMF para los datafiles.** QA usa rutas
`/u02/app/oracle/oradata/CDBUNAP/pdbunap/` que no existen en el
contenedor. Con `DB_CREATE_FILE_DEST` el mismo script sirve en ambos
lados.

---

## Resultado

**La PoC funciona, y es reproducible desde cero.** Verificado destruyendo
el volumen completo (`down -v`), levantando de nuevo y corriendo
`install.sh` sin ninguna intervención manual:

```
install_generalidades.log : 0 errores
load_data.log             : 0 errores
recompile.log             : 0 errores
validate_generalidades.log: 0 errores
objetos invalidos         : 0
exit code                 : 0
```

Objetos creados en `GENERALIDADES`:

```
FUNCTION 1 · INDEX 38 · PACKAGE 23 · PACKAGE BODY 22 · SEQUENCE 12
TABLE 27 · TRIGGER 5 · TYPE 3 · VIEW 14 · LOB 5
```

(`TABLE` e `INDEX` incluyen las tablas internas `DR$…` de Oracle Text.)

Y la prueba que realmente importa — un esquema nuevo consumiendo las
librerías institucionales:

```
PKG_UTILIDADES.TO_FLOAT           = 123,45
Comunas visibles desde APP_DEMO   = 349
Filas en AUDITOR.LOG_SYSTEM       = 1
==> Un esquema externo consumio GENERALIDADES OK
```

`APP_DEMO` llama funciones de `PKG_UTILIDADES`, lee `GRL_COMUNAS_VW` con
sus 349 comunas y escribe en `AUDITOR.LOG_SYSTEM`. Los acentos quedaron
correctos (`PARÁMETROS`, `GÉNEROS`), y no hay ningún DB Link: el entorno
es autónomo, que era la condición dura del jefe.

## Estado

```
FASE 1 — Infraestructura        ✅ completa
FASE 2 — GENERALIDADES          ✅ completa
FASE 3 — Empaquetado automático ⬜ pendiente
FASE 4 — RU 19.31               ⬜ pendiente
```

### Pendiente

- **Preguntar a QA por `FECHA_CREACION`** (ver punto 7 arriba).
- Pedir a QA el conteo `DBA_OBJECTS` de su ambiente depurado, para
  comparar contra el nuestro.
- Reemplazar `30_data/` por el set limpio de QA cuando llegue.
- Confirmar si `GENERALIDADES` tiene sinónimos privados en QA (los 8 del
  inventario eran de DEV).
- Empaquetar para arranque automático (ver
  [`oracle19-poc/COMO_REPLICAR.md`](oracle19-poc/COMO_REPLICAR.md)).
- Subir la imagen al RU 19.31.
