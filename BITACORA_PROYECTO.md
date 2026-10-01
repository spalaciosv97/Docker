# Bitácora — PoC Oracle 19c + GENERALIDADES en Docker

> Resumen de todo lo hecho, en orden, con las decisiones y por qué se
> tomaron. Es el **punto de entrada** del proyecto: un chat nuevo debe
> empezar por la sección siguiente. [`CONTEXTO_ORACLE_DOCKER_POC.md`](CONTEXTO_ORACLE_DOCKER_POC.md)
> es histórico (estado al 11 de agosto).
>
> Última actualización: 29 de septiembre de 2026.

---

## Cómo retomar en un chat nuevo

**Estado en una línea:** hay dos imágenes pre-horneadas listas para
repartir (la 1.0.0 sin ORDS y la 1.1.0 con ORDS sin APEX). Se está
probando en QA un reemplazo nativo de `apex_json` (`PKG_JSON`, en la
rama `grl-json`). Desde el 29-sep se construye en el servidor
`docker-prod.unap.cl` (FASE 6), donde además hay un lab con la 1.1.0.

**Dónde está cada cosa**

| Qué | Dónde |
|---|---|
| Scripts de construcción (fuente de verdad) | `Documents\Docker\oracle19-poc\` — repo git, rama `master` |
| Imagen 1.0.0 para repartir | `Documents\PARA_SERVIDOR\oracle19-generalidades-1.0.0\` |
| Imagen 1.1.0 ORDS para repartir | `Documents\PARA_SERVIDOR\oracle19-generalidades-ords-1.1.0\` |
| `PKG_JSON` / GRL_JSON (en prueba) | rama git `grl-json` + `Documents\GRL_JSON_desarrollo\` (paquete para Desarrollo/QA) |
| Repo compartido de la 1.0.0 | `Documents\oracle19-generalidades\` (repo git aparte) |
| Endpoints ORDS reales de Gedo (referencia) | `Documents\gedo-motor-mapeo\db-snapshot\GEDOTIC\ORDS\Modulos.sql` |

**Git (repo `Documents\Docker`)**

- `master`: exactamente lo que produjo las imágenes 1.0.0 y 1.1.0.
  Construir desde acá da lo mismo que se repartió.
- `grl-json`: `master` + `PKG_JSON` en la imagen y los endpoints
  `/comunas` y `/personas`. **No se reparte** hasta que se decida
  adoptarlo. Si se adopta, sería la 1.2.0.
- Hay un remoto `origin`. Nada se sube sin pedirlo explícitamente.

**Comandos**

```bash
# desde WSL, en oracle19-poc/
./build.sh 1.0.0                    # imagen base
./build.sh 1.1.0 --ords             # + ORDS sin APEX
./build.sh 1.1.0 --ords --reanudar  # retoma desde el commit si fallo el paso 5/6
# la variante --ords-apex esta resuelta pero NO se construye (decision del jefe)
```

**Restricciones que ya costaron tiempo**

- **Disco C: del notebook casi lleno** (~7 GB libres). Un build se cae
  si se llena a mitad (`Bus error`, Docker responde 500). Construir de a
  una variante; en lo posible, construir en el servidor (FASE 6).
- **WSL tiene 6 GB de RAM:** nunca dos builds de Oracle a la vez.
- **Desde PowerShell, no pasar SQL por `docker exec ... bash -c "..."`**:
  las comillas se rompen. Dejar el SQL en un archivo y ejecutarlo con
  `sqlplus @archivo`.
- **Los `.sh` tienen que tener finales LF**: un CRLF falla dentro del
  contenedor sin un error claro.

**Próximos pasos**

1. Resultado de la prueba de `PKG_JSON` en QA
   (`GRL_JSON_desarrollo\04b_comparar_personas.sql`): ¿el formato
   coincide con `apex_json`? Ver la FASE 5 → "GRL_JSON".
2. Servidor `docker-prod` (FASE 6): el SSH con llave ya funciona
   (`ssh docker-prod`) y ya **construye**: la 1.1.0 ORDS salió bien el
   29-sep con `MEM_LIMIT=4g` (ver FASE 6 → "Primer build"). Corre
   producción real (portal de pago, traefik, mongodb…): siempre con
   `MEM_LIMIT=4g`. Su `.tar.gz` carga y arranca: hay un lab
   `oracle19-lab-ords` corriendo ahí (DataGrip por túnel SSH). **Parar el
   lab antes de construir** (no caben los dos en RAM). Flujo:
   `servidor/subir_al_servidor.sh` (notebook) → `servidor/build_servidor.sh`
   (servidor). Ojo: `autoheal` reinicia cualquier contenedor *unhealthy*.
   **Antes de tocar el servidor, leer las reglas de la FASE 6.**
   **Estado del lab al 29-sep: corriendo SIN healthcheck** (para la
   prueba manual de caída con Postman). Al terminar, volver a la normal:
   `cd ~/oracle19-lab-ords && docker compose -p oracle19-lab-ords -f compose.yaml -f compose.servidor.yaml up -d`.
3. Repartir la 1.1.0 (la carpeta de `PARA_SERVIDOR` está lista y
   verificada).
4. ✅ **Notebook liberado (29-sep).** Se borraron de Docker Desktop las 4
   imágenes Oracle, el build cache (10 GB) y el volumen/contenedor de la
   prueba del 28-sep; `fstrim` dentro de la VM. C: pasó de 0 a 7 GB
   libres; falta **compactar el `.vhdx`** (51 GB, `diskpart compact vdisk`
   como administrador, con Docker cerrado y `wsl --shutdown`).
   **El notebook ya no tiene imágenes Oracle:** para construir o probar
   acá, traerlas del servidor, p. ej.
   `ssh docker-prod "docker save local/oracle19c-se2:19.3.0 | gzip -1" | gunzip | docker load`.
   `servidor/subir_al_servidor.sh` sigue sirviendo mientras el servidor
   ya tenga la base y Java/ORDS (los pasos 2 y 3 se saltan). Las trampas
   que había anotadas:
   - Los `.tar.gz` de `PARA_SERVIDOR` (1.0.0 y 1.1.0) son lo que se
     reparte: no borrarlos hasta que estén copiados en otro lado.
   - Borrar imágenes en Docker Desktop **no achica** el disco virtual
     (`docker_data.vhdx`, ~51 GB en C:): el espacio queda libre por
     dentro, no para Windows. Para recuperarlo hay que compactar el
     disco virtual aparte.

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
build.sh              construye, verifica, congela y empaqueta la imagen
compose.build.yaml    SIN volumen en oradata — condición para el commit
compose.lab.yaml      entorno descartable (puerto 1522, volumen propio)
autorun/              dispara install.sh solo, al crearse la base
install.sh            orquestador de los 8 pasos
CHANGELOG.md          qué trae cada versión de la imagen
setup/
  01_pre/             tablespaces, stubs, AUDITOR, SIGESUSTIC, usuario
  10_generalidades/   MASTER_GRL_DOCKER.sql + 80 archivos referenciados
  20_post/            sinónimos públicos (requiere SYS)
  30_data/            datos maestros, aislados para poder reemplazarlos
  35_fixtures/        las 1000 personas sintéticas (semilla fija)
  40_recompile/       recompila los bodies que dependen de los sinónimos
  50_app_demo/        esquema de ejemplo que consume las librerías
  99_validation/      validación + prueba funcional con APP_DEMO
```

Y `Documents\oracle19-generalidades\` — la carpeta que se comparte: solo
`compose.yaml`, `.env`, los scripts de export/import, `README.md`,
`LEEME_PRIMERO.txt` y `SHA256.txt`. **Sin historial de errores**, por
pedido explícito: eso vive acá.

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

---

## FASE 3 — Imagen pre-horneada ✅

### El cambio de enfoque

El plan original era que cada persona corriera `docker compose up` y los
scripts armaran la base en su máquina. El jefe lo descartó: **20-25
minutos de espera por persona, y cada uno arriesgando su propio fallo.**
La instrucción fue «pásale la imagen completa, llegar y ejecutar».

Los scripts **no se botaron**: siguen siendo la fuente de verdad. Se
corren **una sola vez, acá**, y el resultado se congela en una imagen.
Cuando haya que agregar otro esquema, se modifica el script y se
reconstruye — no se parcha la imagen a mano.

```
scripts (fuente de verdad) ──build.sh──► imagen .tar.gz ──► compañeros
        se corre 1 vez acá                   llegar y ejecutar
```

### Cómo se congela la base

`docker commit` sobre el contenedor con la base ya instalada. Dos
condiciones que no son obvias y que rompen el resultado en silencio:

**1. No puede haber volumen montado en `/opt/oracle/oradata` al
construir.** Si lo hay, los datafiles viven en el volumen y `commit` los
ignora — la imagen sale con los binarios pero sin base, y el compañero
espera 25 minutos mientras se reinstala desde cero. Por eso
`compose.build.yaml` no declara ese volumen, mientras el `compose.yaml`
del repo compartido sí.

**2. `Config.Volumes` tiene que quedar en `null`.** Si la imagen
declarara `VOLUME /opt/oracle/oradata`, Docker crearía un volumen anónimo
al arrancar y volvería a tapar los datafiles horneados. Queda en `null`,
pero **no porque `build.sh` lo limpie** (esta bitácora lo decía y era
falso: el `docker commit` no lleva ningún `--change`). Queda en `null`
porque la imagen base, construida con esta versión de `docker-images`,
nunca declaró el `VOLUME`; solo lo menciona en una etiqueta. Verificado
con `docker image inspect` en la FASE 5. Si algún día se reconstruye la
base desde otra versión de `docker-images`, hay que volver a mirarlo.

El síntoma de ambos es el mismo y es fácil de malinterpretar: **arranca
lento**. Por eso el criterio de aceptación es el tiempo de arranque —
25 segundos significa que la base venía horneada; 25 minutos, que salió
vacía.

### El build valida antes de congelar

`build.sh` aborta si `logs/INSTALL_OK` no existe, y **deja el contenedor
en pie a propósito** para poder revisar los logs. Congelar una base con
objetos inválidos sería repartir el error a todo el mundo.

```
1/6 Preparando            4/6 Apagando Oracle limpiamente (SHUTDOWN IMMEDIATE)
2/6 Creando la base       5/6 Congelando (docker commit)
3/6 Verificando ← aborta  6/6 Empaquetando (docker save | gzip)
```

El `SHUTDOWN IMMEDIATE` del paso 4 no es cosmético: congelar una base
abierta dejaría los datafiles inconsistentes.

### Las 1000 personas son sintéticas a propósito

El jefe pidió poblar `GRL_PERSONA`, y **explícitamente que no se
extrajeran de Desarrollo**: la imagen va a circular por lugares que no
controlamos y en Desarrollo las personas son reales.

`setup/35_fixtures/personas.sql` las genera con `DBMS_RANDOM.SEED(42)`,
así que dos builds dan el mismo resultado. Se reconocen a simple vista:
`ID_PERSONA` 900001-901000, correos `@example.invalid` (TLD reservado por
RFC 2606, no resuelve), teléfonos `+56 9 0000 ....`, identificadores en
un rango alto no asignado. El dígito verificador **sí** es válido, para
que sirvan al probar validaciones.

### Tres tropiezos escribiendo el fixture

Los tres son la misma frontera: **PL/SQL y SQL no comparten
vocabulario.** Dentro de un `INSERT`, Oracle está en SQL, y ahí no
existen ni el `BOOLEAN`, ni el `.COUNT` de una colección, ni una función
declarada local al bloque (`PLS-00231`). La solución fue precalcular
todo en variables antes del `INSERT`.

### Resultado de la v1.0.0

```
Arranque                   25 segundos  (era 20-25 min)
Objetos inválidos          0
Personas en GRL_PERSONA    1000
contar_comunas             349
Artefacto                  3,28 GB comprimido / 14,5 GB en disco
```

### La entrega por archivo tiene un modo de fallo propio

Al primer compañero le falló el `docker load` con
`unpigz: corrupted -- incomplete deflate data`. El origen estaba sano
(`gzip -t` OK antes de empaquetar), así que el archivo estaba
incompleto. La causa concreta, confirmada con él: **corrió el
`docker load` cuando la descarga todavía no había terminado.**

Es más fácil de cometer de lo que parece. El archivo aparece en la
carpeta desde el primer byte, con su nombre definitivo, y `docker load`
lo acepta sin chistar: no tiene forma de saber que le van a llegar más
datos. Recién falla varios minutos después, y el mensaje habla de
corrupción — que suena a archivo dañado en origen, no a descarga a
medio camino. Ahí se pierde el tiempo, buscando en el lugar equivocado.

El mismo síntoma lo produce una transferencia cortada, que con 3,3 GB
por red institucional también es común y tampoco avisa.

Se agregó `SHA256.txt` con el tamaño exacto (`3516608206`) y el hash, y
la verificación pasó a ser el **paso 2** del `LEEME_PRIMERO.txt`, antes
de cargar la imagen. Un minuto de comprobación evita quince de espera
inútil. Para copiar desde carpeta de red se recomienda `robocopy /Z`,
que retoma si se corta.

Esto es el argumento fuerte a favor de un registry (`ghcr.io`): un
`docker pull` verifica los digests solo y retoma descargas. Quedó
diferido para no bloquear la primera demo.

---

## FASE 5 — Imagen con ORDS ✅

### El pedido, y el malentendido que había detrás

El jefe pidió una segunda imagen pre-horneada, **en paralelo** a la
1.0.0, con ORDS funcionando. Los endpoints institucionales (Gedo) arman
su JSON con `apex_json`, así que se le planteó que haría falta APEX al
menos en modo runtime. Su respuesta fue que no: que al instalar ORDS
"ya viene APEX". **No es así.** ORDS y APEX son productos distintos, y
`APEX_JSON` es un package de APEX.

Se decidió demostrarlo en vez de discutirlo: construir la imagen sin
APEX y dejar dentro un endpoint que falle por eso. Se preparó además la
variante con APEX, por si la respuesta cambiaba.

Resultado: con la demostración a la vista, el jefe aceptó que
`apex_json` no funciona sin APEX. **Se reparte solo la variante sin
APEX.** La con APEX queda resuelta en los scripts pero no se construye.

### Cómo quedó armado

Los mismos scripts de `setup/` sirven a las dos imágenes, que conviven.
No se forkeó el proyecto:

```
./build.sh 1.0.0            oracle19c-grl:1.0.0        (sin cambios)
./build.sh 1.1.0 --ords     oracle19c-grl-ords:1.1.0   + ORDS
```

- `ords/Dockerfile`: capa delgada sobre la imagen base, con Java 21
  (Temurin) y ORDS 26.2.3, descargados una vez con `ords/descargar.sh`.
  No usa `yum`: OL7 está fuera de soporte.
- `install_ords.sh` corre **después** de `install.sh`: `ords install`
  (crea `ORDS_METADATA` y `ORDS_PUBLIC_USER`), la configuración y el REST
  de `APP_DEMO`. Todo antes del banner, dentro del mismo gate que ya
  usaba `build.sh`.
- `ords/startup/50_ords.sh` va **horneado** en `/opt/oracle/scripts/startup/`,
  que la imagen oficial recorre en cada arranque. Lanza ORDS en segundo
  plano: si lo bloqueara, el contenedor no quedaría nunca `healthy`.
- El healthcheck mira solo la base, a propósito. Un problema de ORDS no
  debe bloquear el acceso por SQL.

### La demostración

Dos endpoints en `APP_DEMO` que son **el mismo bloque PL/SQL**, mismo
`owa_util`, misma respuesta. Solo cambia la librería de JSON:

```
GET /ords/app_demo/v1/prueba        JSON_OBJECT_T (nativo)  → 200 {"data":{"comunas":349,"personas":1000},"status":"OK"}
GET /ords/app_demo/v1/prueba-apex   apex_json               → 403 PLS-00201: identifier 'APEX_JSON.OPEN_OBJECT' must be declared
```

La primera versión de `/prueba` era una consulta SQL que ORDS
serializaba solo. Se cambió a un bloque PL/SQL a pedido, para que la
comparación no dejara lugar a "la diferencia es el tipo de handler". El
error aparece en la respuesta HTTP misma, porque la imagen trae
`debug.printDebugToScreen` activado (entorno de desarrollo).

`build.sh` **exige** ese fallo: si `/prueba-apex` respondiera 200 en la
imagen sin APEX, el build aborta. La imagen no puede salir contradiciendo
lo que demuestra.

### Lo que se encontró de APEX en el código real

En el snapshot de módulos ORDS de GEDOTIC: 62 handlers, y todo el uso de
APEX es `apex_json` (`open/close_object`, `open/close_array`, `write`).
60 de los 62 hacen `apex_json.write(nombre, cursor)`, que serializa un
`SYS_REFCURSOR` en una línea. No se usa ninguna otra parte de APEX. La
recomendación que se llevó al jefe: mantener APEX donde ya está mientras
existan esos handlers, y que los endpoints nuevos se escriban sin
`apex_json`.

### Tropiezos

**ORDS 26 cambió dos banderas de `ords install`.** Rechaza
`--db-pool default` (el pool `default` es implícito) y solo lee la
password de `ORDS_PUBLIC_USER` por stdin si además va `--proxy-user`.
Sin esa bandera falla con "The ORDS_PUBLIC_USER password must be
provided for non-interactive install".

**Una validación que aceptaba un error como respuesta.** La versión de
ORDS se leía con `ords.installed_version`, que como SYS da `ORA-06598`.
El veredicto guardó **el texto del error** como si fuera la versión, y
dio la instalación por buena. Se endureció la función que consulta la
base (cualquier `ORA-` devuelve vacío) y la versión se lee de la vista
`ORDS_METADATA.ORDS_VERSION`. Es la misma lección de la FASE 2: el
criterio tiene que poder fallar.

**Un pool de ORDS roto no se recupera solo.** Iterando sobre el mismo
contenedor, ORDS arrancó con la configuración a medias y marcó el pool
como inválido (`571 DatabaseConnectionError`, "Reconnection was not
attempted"). Solo se arregla reiniciando ORDS. En un build limpio no
pasa, porque la instalación termina antes de que ORDS arranque.

**El alias REST y Database Actions.** Con el alias `demo`, Database
Actions respondía "Credenciales no válidas" con la password correcta:
busca un alias igual al usuario. Se cambió a `app_demo`.

**Disco C: lleno.** El primer `docker commit` murió con `Bus error`: C:
había llegado a 0 bytes libres (el disco virtual de Docker vive ahí).
Tras eso el motor respondía `500` a todo y WSL no podía arrancar Ubuntu
(`Wsl/Service/CreateInstance/E_FAIL`). Se liberaron ~23 GB dentro de
Docker (contenedores viejos `oracle19-lab`, `oracle19-poc` y
`oracle19-grl` con sus volúmenes, y la caché de build). Se agregó
`build.sh --reanudar`, que retoma desde el commit sobre un contenedor ya
verificado sin rehacer la base.

### Resultado de la 1.1.0-ords

Probado como un compañero, en un contenedor nuevo, desde la carpeta de
distribución:

```
Primer arranque     base ~2-4 min (copia al volumen), ORDS ~30 s después
Reinicio            base ~30-50 s, ORDS ~20-30 s después
/prueba             200   {"data":{"comunas":349,"personas":1000},"status":"OK"}
/prueba-apex        403   PLS-00201 ... APEX_JSON.OPEN_OBJECT
Database Actions    alias app_demo + credenciales de APP_DEMO: 200 (y 401 con
                    password mala), probado por REST-Enabled SQL. Falta
                    confirmar la pantalla de login en el navegador.
Artefacto           3 771 433 861 bytes / 15,1 GB en disco
SHA256              5105B5F6CE039C12E211F2FB53082E9DE9551C1AE352BEDCB8B8E126C4F97F24
```

Carpeta lista para repartir:
`Documents\PARA_SERVIDOR\oracle19-generalidades-ords-1.1.0\`. En git,
es el estado de la rama `master`.

### GRL_JSON: reemplazo nativo de `apex_json` (en prueba, rama `grl-json`)

Después de la demostración surgió la pregunta de fondo: ¿se puede
prescindir de APEX? Del código de Gedo, lo único que no tiene
equivalente nativo directo es `apex_json.write(nombre, cursor)`, que
convierte un `SYS_REFCURSOR` entero a JSON. Lo demás es `JSON_OBJECT_T`.

Se escribió `PKG_JSON` (sinónimo público `GRL_JSON`), con dos piezas:

- `cursor_a_json(cursor)`: describe el cursor con `DBMS_SQL` y arma un
  `JSON_ARRAY_T`, con los nombres de columna como claves.
- `imprimir(json)`: lo manda por `htp` en trozos, porque `htp.p` admite
  como máximo 32767 caracteres por llamada.

Probado en la imagen: 349 comunas, 1000 personas (201 KB en una
respuesta), error del handler como 500 limpio, nulos, fechas, `CLOB`,
escapes, acentos y un error claro con tipos no soportados.

**Sin confirmar:** que el formato sea idéntico al de `apex_json`
(fechas, nulos, mayúsculas en las claves). Solo se puede confirmar donde
hay APEX. **En QA ya está instalado en GENERALIDADES** y se corrieron
los pasos 01-03; falta `04b_comparar_personas.sql` con las ~20 000
personas reales.

`PKG_PERSONA.GET_ALL` de QA **no sirve** para esa comparación: devuelve
un `CLOB` ya armado con `JSON_ARRAYAGG`, no un cursor, y corta en 10 000
filas. De paso muestra que GENERALIDADES ya arma JSON sin APEX en código
en uso.

**Por qué va en una rama aparte:** no está decidido si se va a usar, y
la imagen 1.1.0 que se reparte no lo trae. En `grl-json` la imagen lo
instala (`setup/60_ords/05_pkg_json.sql` y `06_...`) y `build.sh`
valida `/comunas` y `/personas`. Si se adopta, pasa a GENERALIDADES por
el compañero de QA y sería la imagen 1.2.0.

---

## FASE 6 — Servidor `docker-prod` (en curso)

El disco del notebook no da para seguir construyendo imágenes, y el
jefe dio acceso a un servidor Docker de la universidad:

```
docker-prod.unap.cl   172.19.82.189
usuarios: "desarrollo" y "spalaciosv"
```

**Estado al 29-sep:** el SSH está en el **puerto 2200**, no en el 22
(lo confirmó el administrador). Desde el notebook, en el Wi-Fi de la
universidad (`10.20.125.166`), el 2200 **responde**; el 22 no. Todavía
no se hizo ningún login.

```
ssh -p 2200 spalaciosv@docker-prod.unap.cl
```

### Acceso SSH (resuelto el 29-sep)

Se creó una llave **dedicada** para este servidor, sin reutilizar
`~/.ssh/id_rsa` (que sirve para otras cosas): así se puede revocar sola.

| Qué | Valor |
|---|---|
| Llave | `~/.ssh/id_ed25519_dockerprod` (ed25519, **sin passphrase**, para que Claude la use sin pedirla; es dedicada y revocable) |
| Huella de la llave | `SHA256:qq3E4u6244UXnDn4OkgubPntusZcmuzxExLVLBbgKrA` |
| Alias | `~/.ssh/config` → `Host docker-prod` (puerto 2200, usuario `spalaciosv`, `IdentitiesOnly yes`) |
| Huella del servidor (ED25519) | `SHA256:ebNVeuIBYIay1EzpkDp396o47BChrd82JT8fqhXM0fE` |

La registró la persona en su terminal (contraseña tecleada por ella):
`Get-Content ~/.ssh/id_ed25519_dockerprod.pub | ssh docker-prod "umask 077; mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"`.
Desde ahí: `ssh docker-prod "..."`, sin contraseña.

### Reconocimiento (29-sep, solo lectura)

| | |
|---|---|
| Sistema | Rocky Linux 9.6, 4 CPU |
| RAM | 7,3 GiB total, **~5,2 GiB disponible** (2,2 usados por otros); swap 7,7 GiB |
| Disco `/` (ahí vive `/var/lib/docker`) | 70 GB, **50 GB libres** |
| Disco `/home` | 121 GB, 120 GB libres |
| Docker | Engine 28.3.2 (cliente) |
| `id` | `spalaciosv`, grupos `spalaciosv`, `desarrollo`, `devopsdocker` |

**Bloqueo: `spalaciosv` no puede usar Docker.** `docker version` y
`docker ps` dan *permission denied* en `/var/run/docker.sock`
(`root:docker`, modo 660). En `/etc/group`:

```
docker:x:980:desarrollo,devopsdocker
devopsdocker:x:1001:spalaciosv
```

Parece que se quiso dar acceso metiendo el **grupo** `devopsdocker`
dentro de `docker`, pero Linux no anida grupos: esa lista es de
*usuarios*. Resultado: el usuario `desarrollo` sí tiene Docker;
`spalaciosv` no. **No se intentó ningún atajo** (ni `sudo`, ni entrar
como `desarrollo`). Hay que pedirle al administrador:
`usermod -aG docker spalaciosv` (y volver a entrar por SSH).
Recordar que el grupo `docker` equivale a root en la máquina.

**Resuelto el mismo 29-sep:** el administrador agregó `spalaciosv` al
grupo `docker`. Ya se puede usar Docker con el usuario personal.

### Qué corre en el servidor (29-sep, solo lectura)

Es **producción real**: 12 contenedores arriba desde hace 5 semanas,
ninguno nuestro.

| Grupo | Contenedores | Puertos publicados |
|---|---|---|
| Portal de pago | `portal-pago-api`, `portal-pago-svc`, `portal-pago-caja-svc` | (detrás de traefik) |
| Microservicios | `login-svc`, `redis-svc`, `mongo-svc` | (detrás de traefik) |
| Proxy | `traefik` | `0.0.0.0:80`, `0.0.0.0:8081` |
| Datos | `mongodb`, `redis`, `influxdb` | `27017`, `6379`, `8086` |
| Monitoreo | `grafana`, `autoheal` | `3000` |
| Detenidos (ajenos) | `wonderful_edison` (ingest-api), `blissful_tharp` (hello-world) | `8000` |

`docker system df`: 23 imágenes (9,7 GB), 5 volúmenes (0,7 GB), sin
build cache. Docker vive en `/var/lib/docker` (overlay2), dentro de `/`
con **50 GB libres**.

**Puertos ya ocupados** en el host: 80, 3000, 6379, 8000, 8081, 8086,
27017. Los nuestros (1521, 8082), siempre en `127.0.0.1`, no chocan.

**El riesgo real es la RAM, no el disco.** Hay 7,3 GiB en total y
~5,1 GiB disponibles. Un build de Oracle usa ~6 GB: sin límite, el
kernel empezaría a usar swap y, en el peor caso, el *OOM killer* podría
matar un contenedor del **portal de pago** o `mongodb`. Antes del primer
build:

1. Preguntar al jefe cuánta RAM se puede usar y en qué horario.
2. Correr el contenedor de build **con límite de memoria**
   (`--memory`), aunque vaya más lento, y ajustar SGA/PGA para que quepa.
3. Mirar `free -h` justo antes y vigilar durante el build.

(El jefe confirmó que hay swap, pero igual se decidió limitar a 4 GB.)

### Primer build en el servidor (29-sep, 1.1.0 con ORDS)

**Cómo se llevó todo al servidor, sin volver a descargar nada:**

- Código: `git archive` del árbol de trabajo → `~/oracle19-poc` (en
  `/home`, 120 GB libres). Ahí queda también el `.tar.gz` (`dist/`).
- Imagen `local/oracle19c-se2:19.3.0`: `docker save | gzip -1 | ssh
  docker-prod "pigz -dc | docker load"`, en streaming: no ocupa disco del
  notebook. 10,5 min. Los ID difieren (Docker Desktop usa el almacén de
  containerd), pero las 9 capas (`RootFS.Layers`) son idénticas.
- Imagen ORDS: en vez de mandar otros 10 GB, se sacaron del
  contenedor del notebook los binarios exactos (`/opt/java/jre21` y
  `/opt/oracle/ords/product`, ~350 MB) a `ords/downloads/{jre,ords}` y se
  corrió `ords/construir_base.sh` en el servidor. **No** se usó
  `descargar.sh`: sus URL son *latest* y habría cambiado las versiones.

**Las imágenes y el contenedor de build quedan en `/`** (`/var/lib/docker`,
43 GB libres), no en `/home`: es donde el daemon guarda todo, y moverlo
exigiría reconfigurar y reiniciar Docker en producción. Un build suma
~10 GB ahí.

**Cambios al build que salieron de esto** (no cambian la imagen):

1. **Memoria de Oracle fijada** en los compose de build:
   `INIT_SGA_SIZE=2055`, `INIT_PGA_SIZE=685`. Son los valores horneados
   en la 1.0.0 y la 1.1.0 (`strings spfileDEMOCDB.ora`), que dbca había
   calculado solo según la RAM del notebook. Sin fijarlos, con un límite
   de 4 GB `createDB.sh` le daría a Oracle **los 4 GB completos**
   (`totalMemory` = memoria del contenedor) y no quedaría nada para dbca.
2. **`MEM_LIMIT=4g ./build.sh ...`**: límite opcional (`mem_limit`), sin
   swap extra salvo `MEMSWAP_LIMIT`. En el notebook, sin límite.
3. **`ulimits nofile=1048576`** en los compose de build. El primer
   intento murió al minuto: `library initialization failed - unable to
   allocate file descriptor table - out of memory`. El Docker del
   servidor da `nofile=1073741816` (Docker Desktop: 1048576), y el Java
   de dbca reserva una tabla de ese tamaño. No era el límite de 4 GB.
4. **`chmod a+rwx` a la carpeta de logs** en `build.sh`: en Linux el
   contenedor escribe como `oracle` (uid 54321). Si no puede,
   `install.sh` cae a `/tmp`, el paso 3 no ve `INSTALL_OK` y los logs
   quedarían horneados.

Se lanza con `nohup setsid` para que sobreviva a un corte del SSH:

```bash
cd ~/oracle19-poc && MEM_LIMIT=4g nohup setsid ./build.sh 1.1.0 --ords \
  > logs/build_ords_1.1.0.log 2>&1 < /dev/null &
```

**Resultado: ✅ build completo en ~28 min** (12:21 → 12:49).

- Verificación del paso 3 igual que en el notebook: `ords=26.2.3
  invalidos=0 rest=1 handlers=2`, `/prueba` → 200 con 349 comunas y
  1000 personas, `/prueba-apex` → 403 con `PLS-00201 APEX_JSON`.
- Memoria del contenedor: máximo ~3,3 de 4 GiB. El servidor nunca bajó
  de ~2,2 GB disponibles y la swap casi no se movió (~100-140 MB).
- `dist/oracle19c-grl-ords-1.1.0.tar.gz`: 4,1 GB, `gzip -t` OK, sha256
  `427d94fe…4dccb3f`. Es más grande que el del notebook (3,8 GB) porque
  `docker save` del almacén clásico exporta las capas en otro formato; no
  es byte a byte el mismo archivo.
- Después del build: `/` con 39 GB libres, `/home` con 116 GB. No quedan
  contenedores `oracle19*`. Quedan en el servidor las imágenes
  `local/oracle19c-se2:19.3.0`, `local/oracle19c-se2-ords:19.3.0` y
  `oracle19c-grl-ords:1.1.0`.

### Lab en el servidor desde el `.tar.gz` (29-sep) ✅

Prueba del camino de los compañeros: se borró la imagen del build
(`docker rmi oracle19c-grl-ords:1.1.0`) y se cargó desde el archivo.
`docker load` 81 s, base lista en 20 s, `/prueba` →
`{"comunas":349,"personas":1000}`, login `GENERALIDADES@//127.0.0.1:1521/DEMOPDB`
OK.

En `~/oracle19-lab-ords/`: el `compose.yaml` de `PARA_SERVIDOR` **sin
tocar** + `compose.servidor.yaml` encima (nombre `oracle19-lab-ords`,
4 GB sin swap, `nofile`, puertos `127.0.0.1:1521` y `127.0.0.1:8082`):

```bash
cd ~/oracle19-lab-ords
docker compose -p oracle19-lab-ords -f compose.yaml -f compose.servidor.yaml up -d   # o stop
```

Volumen: `oracle19-lab-ords_oracle_grl_ords_data` (los datos del lab).

**Queda corriendo y usa ~3 GB de RAM** (el servidor queda con ~2,3 GB
disponibles). **Lab y build no caben a la vez:** antes de un build,
`... stop` el lab.

**Desde DataGrip (notebook):** conexión Oracle con host `localhost`,
puerto `1521`, Service Name `DEMOPDB`, usuario `GENERALIDADES`, y en la
pestaña SSH/SSL un túnel a `docker-prod.unap.cl:2200`, usuario
`spalaciosv`, llave `~/.ssh/id_ed25519_dockerprod`. ORDS en el navegador:
`ssh -N -L 8080:127.0.0.1:8082 docker-prod` y `http://localhost:8080/ords/...`.

El primer intento en DataGrip dio `ORA-12541 ... localhost port 1521`:
fue directo al notebook, sin túnel (la pestaña SSH/SSL no quedó
activa). El túnel sí funciona (probado). Lo más simple es abrir el
túnel a mano, `ssh -N -L 1522:127.0.0.1:1521 docker-prod`, y en
DataGrip usar `localhost:1522` **sin** configuración SSH.

### `autoheal` también vigila lo nuestro

En el servidor corre `willfarrell/autoheal` con
`AUTOHEAL_CONTAINER_LABEL=all`: **reinicia a la fuerza (10 s de gracia)
cualquier contenedor *unhealthy***, también los `oracle19-*`. Con el
healthcheck del lab (20 fallos × 20 s), una base caída ~7 min provoca un
reinicio. Durante un build no molesta (`start_period` de 40-90 min).

### Prueba: ¿qué hace ORDS si se cae la base? (29-sep, en el lab)

Script: `servidor/lab/prueba_caida_bd.sh` (resultado en
`~/oracle19-lab-ords/pruebas/` del servidor). Se bajó la base dentro
del contenedor, con ORDS vivo, dos veces:

| | `/prueba`, `/prueba-apex`, `/sql-developer` |
|---|---|
| Base arriba | 200 / 403 (`PLS-00201`, esperado) / 200 |
| `SHUTDOWN IMMEDIATE` | **HTTP 571** `DatabaseConnectionError`, en **9-15 s** cada una |
| `SHUTDOWN ABORT` (como corte de luz) | igual: 571 en 9-15 s |
| Después de `STARTUP` | 200 **en ~1 s**, sin reiniciar ORDS |

Conclusiones:

- **ORDS no se cae** con la base: el proceso sigue vivo y responde un
  JSON de error propio:
  `{"code":"DatabaseConnectionError","title":"Database Connection Error","message":"Contact your system administrator and provide the request ECID..."}`.
- **571 no es un código HTTP estándar** (es de ORDS). Está en el rango
  5xx, así que un cliente que trate "≥ 500 = error del servidor" lo
  maneja; uno que compare contra una lista (500, 502, 503) no.
- **Cada request tarda 9-15 s** en fallar (ORDS intenta abrir la
  conexión antes de rendirse). Un backend que llame a ORDS con timeout
  corto verá *timeout*, no el 571.
- **Se recupera solo** en ~1 s después de abrir la base, y la PDB abre
  sola en `READ WRITE` (estado guardado). Tras el `ABORT`, la
  recuperación de instancia no dio problemas.
- El contenedor siguió `healthy`, 0 reinicios (caídas < 3 min, antes de
  que `autoheal` actúe).

Para repetirla **a mano** (Postman/Hoppscotch por túnel) con la base
abajo el tiempo que se quiera, el lab se recreó (29-sep) **sin
healthcheck** (`servidor/lab/compose.sin-healthcheck.yaml`): así
`autoheal` no lo toca. Se baja y sube con `bajar_bd.sh [abort]` y
`subir_bd.sh` en `~/oracle19-lab-ords/`. Para volver al lab normal:
`up -d` sin ese archivo.

### Carpeta `servidor/` (29-sep)

Se decidió **no** separar el repo ni hacer una rama para el servidor:
los dos builds corren los mismos scripts, y dos copias terminarían
divergiendo. En `oracle19-poc/servidor/`:

| Archivo | Dónde se corre | Qué hace |
|---|---|---|
| `subir_al_servidor.sh` | notebook | código del último commit, imagen base, Java/ORDS exactos (solo lo que falte) |
| `build_servidor.sh` | servidor | `MEM_LIMIT=4g` + `nohup` + log; no arranca si el lab corre |
| `lab/compose.servidor.yaml` | servidor | override del lab (nombre, 4 GB, `nofile`, puertos) |
| `lab/prueba_caida_bd.sh` | servidor | la prueba de arriba |

Ver `COMO_REPLICAR.md` → "Construir en el servidor docker-prod".

Dos trampas de `git archive` al escribir `subir_al_servidor.sh`, las dos
silenciosas: desde la subcarpeta, `HEAD:oracle19-poc` da un árbol
**vacío** sin error; y con `core.autocrlf=true` entrega los `.sh` con
**CRLF** pese a `eol=lf`. Se usa `git -c core.autocrlf=false archive
HEAD` y el script verifica que llegó `servidor/` y que ningún `.sh`
tenga CRLF.

**Cómo se trabajaría:** Claude Code sigue en el notebook y ejecuta
comandos en el servidor por SSH (`ssh usuario@docker-prod.unap.cl
"..."`). Para eso hace falta una **llave SSH**: se genera en el
notebook y la persona la registra en el servidor una sola vez, tecleando
ella la contraseña en su terminal. **La contraseña nunca se escribe en
el chat.**

**Sobre los dos usuarios:** `spalaciosv` parece personal y `desarrollo`
compartido. Usar el personal, para que quede claro quién hizo qué, salvo
que el administrador diga otra cosa. Confirmar cuál tiene permiso para
usar Docker.

### Para qué se va a usar (decidido el 29-sep)

**Solo como máquina de trabajo propia: construir, generar el `.tar.gz`
y probar.** Los compañeros siguen como hasta ahora: reciben el
`.tar.gz` y levantan la imagen **en su equipo**. En el servidor no queda
nada corriendo para otros.

```
servidor docker-prod                          compañeros
  ./build.sh  ──► imagen ──► .tar.gz  ──copia──►  docker load + compose up (local)
                    │
                    └──► lab propio para probar (oracle19-lab-*)
```

| Uso | Nombres |
|---|---|
| Construir imágenes y `.tar.gz` | contenedores `oracle19-build-*`, imágenes `oracle19c-grl*:<versión>` |
| Pruebas propias | contenedores `oracle19-lab-*` |

**Descartado por ahora: una base compartida** a la que se conecten
todos por red. Cambiaría la naturaleza del proyecto (dejaría de ser
local y descartable) y obligaría a resolver contraseñas propias, acceso
por red, errores visibles de ORDS y respaldos.

Como en el servidor los puertos quedan en `127.0.0.1`, para probar desde
el notebook (Postman, DataGrip, el navegador) se usa un **túnel SSH**,
por ejemplo `ssh -p 2200 -L 8080:127.0.0.1:8082 spalaciosv@docker-prod.unap.cl`,
y luego `http://localhost:8080/...` en el notebook.

Docker no tiene permisos por usuario: cualquiera con acceso a Docker en
el servidor puede parar o borrar cualquier contenedor, imagen o
volumen. Lo que evita pisarse son los nombres y el acuerdo, no una
restricción técnica.

### Reglas para trabajar en `docker-prod`

Es un servidor de **producción** compartido. Lo acordado:

1. **Solo tocar lo nuestro.** Todo lo que se cree lleva el prefijo
   `oracle19`: contenedores, volúmenes, imágenes, redes y proyectos de
   compose. Nunca parar, borrar ni modificar nada que no lo tenga.
2. **Nada de limpieza general:** ni `docker system prune`, ni
   `docker image prune`, ni `docker volume prune`, ni
   `docker builder prune`. Borran cosas de otros. Para borrar algo
   nuestro, se borra por nombre.
3. **Antes de cualquier cosa pesada**, mirar recursos (`df -h`,
   `free -h`, `docker ps`) y avisar. Corre **producción real** (portal de
   pago, `login-svc`, `traefik` en :80, `mongodb`, `redis`, `grafana`) y
   solo hay ~5 GB de RAM libres de 7,3.
4. **Memoria: siempre con tope de 4 GB, sin swap extra.** Builds con
   `servidor/build_servidor.sh` (= `MEM_LIMIT=4g`); el lab con
   `compose.servidor.yaml` (`mem_limit: 4g`). Si algo se pasa, muere lo
   nuestro y no lo de otros. Pico real de un build: ~3,3 GB.
5. **Lab y build nunca a la vez:** no caben (~3 GB + ~3,3 GB).
   `build_servidor.sh` se niega si el lab corre.
6. **Puertos:** no publicar nada sin acordarlo. Solo en `127.0.0.1`,
   nunca `0.0.0.0` (los endpoints de ORDS son anónimos). Desde el
   notebook, por túnel SSH. Ya ocupados por otros: 80, 3000, 6379, 8000,
   8081, 8086, 27017.
7. **Nada fuera de nuestras carpetas** (`~/oracle19-poc`,
   `~/oracle19-lab-ords`): ni paquetes del sistema, ni servicios, ni la
   **configuración de Docker**. En particular, no mover el data-root a
   `/home` ni reiniciar Docker: bajaría la producción.
8. **Sin atajos de permisos:** nada de `sudo`, ni entrar como el
   usuario `desarrollo`. Si falta un permiso, se le pide al
   administrador (así se resolvió el grupo `docker`). La contraseña
   nunca va en el chat: se entra con la llave.
9. **Ojo con `autoheal`** (`AUTOHEAL_CONTAINER_LABEL=all`): reinicia a la
   fuerza cualquier contenedor *unhealthy*, también los nuestros. Para
   pruebas con la base abajo, lab sin healthcheck
   (`compose.sin-healthcheck.yaml`), y volver a la normal al terminar.
10. **Para qué es** (decidido el 29-sep): solo máquina de trabajo propia
    (construir, `.tar.gz`, probar). Nada queda corriendo para otros.
    Sigue pendiente preguntarle al jefe cuánto disco se puede usar.

Estas reglas son **del servidor**. En el notebook (Docker Desktop
propio) sí se puede limpiar con `prune`.

---

## Estado

```
FASE 1 — Infraestructura        ✅ completa
FASE 2 — GENERALIDADES          ✅ completa
FASE 3 — Imagen pre-horneada    ✅ completa (v1.0.0 entregada)
FASE 4 — RU 19.31               ⬜ pendiente
FASE 5 — Imagen con ORDS        ✅ completa (1.1.0-ords, sin APEX)
         GRL_JSON (sin APEX)    🔄 en prueba en QA (rama grl-json)
FASE 6 — Servidor docker-prod   🔄 en curso (build + lab OK; flujo en servidor/)
```

### Pendiente

**Deuda técnica propia — lo más urgente**

- **`tools/preparar_entrega_qa.ps1` no existe.** Las tres
  transformaciones que se le hicieron a los archivos de QA (los 545
  `;` agregados, los 19 archivos convertidos de CP1252 a UTF-8, los 13
  packages de test eliminados) se corrieron a mano y **no quedaron
  versionadas**. Mientras siga así, una entrega nueva de QA no se puede
  procesar sin repetir el trabajo a ciegas.

**Preguntas abiertas a QA**

- **`FECHA_CREACION`** (ver punto 7 arriba). Parchado local a
  `FECHA_REG`, 4 ocurrencias, marcadas con comentario.
- `GRL_PERSONA.ID_PERSONA` no tiene trigger que lo asigne. Confirmar si
  es así en QA o si falta el objeto.
- El conteo `DBA_OBJECTS` de su ambiente depurado, para comparar.
- Si `GENERALIDADES` tiene sinónimos privados en QA (los 8 del
  inventario eran de DEV).
- Reemplazar `30_data/` por el set limpio de QA cuando llegue.

**Preguntas abiertas al DBA**

- Qué versiones de ORDS y APEX corren en DEV, QA y PROD. La imagen usa
  ORDS 26.2.3 (fijada en `ords/VERSIONES.txt`); un endpoint
  que anda acá podría no andar en un ORDS institucional más viejo.

**Diferido por decisión**

- Variante con APEX runtime (`./build.sh 1.1.0 --ords-apex`): resuelta
  en los scripts, no construida. Requiere volver a correr
  `ords/descargar.sh`: el zip de APEX se borró para liberar disco.
- Verificar que `./build.sh` **sin** bandera siga produciendo lo mismo
  que la 1.0.0. El código de ese camino no cambió, pero no se corrió un
  build de regresión.

- `ghcr.io` como registry privado, para dejar de copiar 3,3 GB a mano.
- Subir la imagen al RU 19.31 (sería la v2.0.0).
- Confirmar con el equipo el rango de identificadores sintéticos.
- ~~Evaluar una instancia en el servidor~~ → ahora es la FASE 6.
