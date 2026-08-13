# CONTEXTO — PoC Oracle 19c + GENERALIDADES en Docker

> **Objetivo de este archivo:** entregar todo el contexto acumulado del trabajo para continuar desde otra sesión de ChatGPT, idealmente desde la aplicación de escritorio con acceso a la carpeta completa de scripts de QA.
>
> **Fecha de estado:** 11 de agosto de 2026.
>
> **Importante para el siguiente agente/chat:** antes de ejecutar scripts, revisar recursivamente la carpeta de QA y adaptar los scripts al entorno Linux/Docker. No asumir que las rutas Windows del equipo del compañero funcionarán dentro del contenedor. No ejecutar comandos destructivos (`docker compose down -v`, `docker volume rm`, etc.) hasta tener claro qué volumen se está utilizando.

---

# 1. Qué pidió el jefe

El objetivo NO es usar un DB Link hacia Desarrollo/QA.

El jefe quiere evaluar la factibilidad de tener un ambiente Oracle Docker **autónomo**, que venga con las librerías institucionales del esquema `GENERALIDADES`, de manera que después otra persona pueda agregar su propio esquema de aplicación.

La idea conceptual es:

```text
Oracle Docker institucional/base
│
├── Oracle Database 19c Standard Edition 2
│
├── GENERALIDADES
│   ├── tablas
│   ├── índices
│   ├── secuencias
│   ├── tipos
│   ├── triggers
│   ├── vistas
│   ├── funciones
│   ├── procedimientos
│   ├── package specs
│   ├── package bodies
│   ├── sinónimos
│   └── datos mínimos que realmente sean necesarios
│
├── dependencias mínimas necesarias de otros esquemas
│   ├── AUDITOR
│   └── SIGESUSTIC
│
└── el desarrollador agrega:
    └── SU_ESQUEMA
        ├── tablas
        ├── packages
        └── aplicación
```

La meta es que el entorno pueda funcionar sin depender de Desarrollo, QA, VPN o DB Links.

---

# 2. Alcance de la PoC

La PoC (“Proof of Concept” / prueba de concepto) busca responder:

1. ¿Oracle 19c SE2 funciona correctamente dentro de Docker?
2. ¿Puede persistir la base aunque el contenedor sea eliminado y recreado?
3. ¿Puede reproducirse el charset institucional?
4. ¿Se puede instalar `GENERALIDADES` dentro de ese Oracle?
5. ¿Se pueden resolver sus dependencias externas mínimas?
6. ¿Puede un esquema nuevo consumir packages de `GENERALIDADES`?
7. ¿Puede posteriormente conectarse un backend externo/local a esta base?
8. ¿Puede dejarse todo reproducible mediante Docker Compose + scripts?
9. Posteriormente: ¿se puede igualar el Release Update institucional 19.31?

No se está intentando todavía montar:
- servidor público de demos;
- reverse proxy;
- HTTPS;
- infraestructura productiva;
- monitoreo completo;
- alta disponibilidad.

Eso queda fuera del scope inicial.

---

# 3. Ambiente institucional conocido

La base institucional consultada reporta:

```text
Oracle Database 19c Standard Edition 2 Release 19.0.0.0.0 - Production
Version 19.31.0.0.0
```

Charsets:

```text
NLS_CHARACTERSET       = AL32UTF8
NLS_NCHAR_CHARACTERSET = AL16UTF16
```

Por lo tanto, el objetivo final de compatibilidad sería:

```text
Oracle Database: 19c
Edition:          Standard Edition 2
RU objetivo:      19.31
Charset:          AL32UTF8
NCHAR charset:    AL16UTF16
```

---

# 4. Ambiente local actual

## Windows

```text
Microsoft Windows
Versión: 10.0.26200.8893
Usuario Windows: sebapalacios
Equipo: DESKTOP-QLB92K2
```

## WSL

WSL 2 está funcionando nuevamente.

Distribución:

```text
Ubuntu
WSL version: 2
Usuario Unix creado: seba
Home esperado: /home/seba
```

Hubo inicialmente este error:

```text
Wsl/Service/E_UNEXPECTED
Error catastrófico
```

Se reparó/reinició WSL y finalmente Ubuntu logró iniciar y crear el usuario Unix.

## Docker

Docker Desktop está funcionando integrado con WSL.

Salida relevante observada:

```text
Docker Client: 29.6.2
Docker Server: 29.6.2
Docker Compose plugin: v5.3.1
Operating System: Docker Desktop
OSType: linux
Architecture: x86_64
CPUs: 16
Memory visible por Docker: ~6.693 GiB
Kernel: microsoft-standard-WSL2
```

Docker está trabajando con contenedores Linux.

---

# 5. Construcción de Oracle 19c SE2

Se descargó desde Oracle:

```text
LINUX.X64_193000_db_home.zip
```

NO se usó el RPM Enterprise Edition.

Se clonó el repositorio oficial:

```text
https://github.com/oracle/docker-images.git
```

Ubicación utilizada:

```text
~/docker-images/OracleDatabase/SingleInstance/dockerfiles
```

El ZIP fue colocado en:

```text
~/docker-images/OracleDatabase/SingleInstance/dockerfiles/19.3.0/
```

Se ejecutó:

```bash
./buildContainerImage.sh \
  -v 19.3.0 \
  -s \
  -t local/oracle19c-se2:19.3.0
```

Significado:

```text
-v 19.3.0  = Oracle 19c base (19.3)
-s         = Standard Edition 2
-t         = tag local elegido
```

La construcción terminó correctamente:

```text
Oracle Database container image for 'se2' version 19.3.0 is ready to be extended:

--> local/oracle19c-se2:19.3.0
```

Tiempo de build observado: ~1149 segundos.

Imagen actual:

```text
local/oracle19c-se2:19.3.0
```

---

# 6. Importante: 19.3 vs 19.31

La PoC actualmente está en:

```text
19.3.0.0.0
```

La universidad usa:

```text
19.31.0.0.0
```

Ambos son Oracle 19c.

19.3 es la base/gold image utilizada para construir Oracle 19c.  
19.31 es un Release Update acumulativo posterior.

Decisión tomada:

1. Primero demostrar la factibilidad completa con 19.3.
2. Después obtener con el DBA el RU 19.31 correcto.
3. Construir una segunda imagen parcheada.
4. Revisar también one-off patches y salida de `opatch lsinventory`.
5. No declarar equivalencia exacta con QA/DEV hasta igualar el RU.

Datos que luego se solicitarán al DBA:

```sql
SELECT
    patch_id,
    patch_type,
    action,
    status,
    action_time,
    description
FROM dba_registry_sqlpatch
ORDER BY action_time;
```

Y en SO:

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

---

# 7. Proyecto Docker actual

Se creó:

```text
/home/seba/oracle19-poc
```

Nombre PoC = Proof of Concept.

Conceptualmente contiene:

```text
oracle19-poc/
├── compose.yaml
├── .env
└── setup/       ← se utilizará para scripts de GENERALIDADES
```

La configuración utilizada crea:

```text
CDB: DEMOCDB
PDB: DEMOPDB
```

## Qué es CDB

CDB = Container Database.

```text
DEMOCDB
├── CDB$ROOT
├── PDB$SEED
└── DEMOPDB
```

Es el contenedor multitenant principal de Oracle.

## Qué es PDB

PDB = Pluggable Database.

`DEMOPDB` es donde deben vivir los esquemas de aplicación:

```text
DEMOPDB
├── GENERALIDADES
├── AUDITOR (mínimo si es necesario)
├── SIGESUSTIC (mínimo si es necesario)
└── ESQUEMA_DEL_DESARROLLADOR
```

Para conexiones desde Windows/DataGrip se usa:

```text
Host:         127.0.0.1
Port:         1521
Connection:   Service Name
Service Name: DEMOPDB
```

No utilizar `DEMOPDB` como SID.

---

# 8. Persistencia actual

La base utiliza un volumen Docker montado en:

```text
/opt/oracle/oradata
```

Conceptualmente:

```text
Imagen:
local/oracle19c-se2:19.3.0
        ↓
Contenedor:
oracle19-poc
        ↓
Oracle:
DEMOCDB / DEMOPDB
        ↓
/opt/oracle/oradata
        ↓
Volumen Docker persistente
```

Se probó la persistencia:

1. Se creó información en Oracle.
2. Se ejecutó `docker compose down`.
3. El contenedor fue recreado.
4. El volumen permaneció.
5. La información siguió existiendo.

Resultado:

```text
✅ Persistencia comprobada
```

No ejecutar:

```bash
docker compose down -v
```

salvo cuando explícitamente se quiera borrar la base completa para probar una instalación limpia, porque `-v` elimina también el volumen.

---

# 9. Estado actual del contenedor Oracle

El Oracle actual arrancó correctamente.

Log relevante:

```text
Oracle Database 19c Standard Edition 2 Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

#########################
DATABASE IS READY TO USE!
#########################
```

Estado de Docker observado:

```text
oracle19-poc
IMAGE: local/oracle19c-se2:19.3.0
STATUS: Up (...) (healthy)
PORT: 127.0.0.1:1521->1521/tcp
```

Resultado:

```text
✅ Oracle está healthy
✅ Listener accesible desde Windows
✅ DataGrip conecta
```

---

# 10. Charset comprobado dentro del Docker

Resultado real consultado:

```text
PARAMETER                 VALUE
NLS_NCHAR_CHARACTERSET    AL16UTF16
NLS_CHARACTERSET          AL32UTF8
```

Esto coincide con la base institucional.

Resultado:

```text
✅ NLS_CHARACTERSET coincide
✅ NLS_NCHAR_CHARACTERSET coincide
```

---

# 11. Docker vs Docker Compose

Docker es el motor que maneja:

```text
imágenes
contenedores
volúmenes
redes
```

Ejemplos:

```bash
docker ps
docker images
docker volume ls
docker logs
```

Docker Compose permite declarar la configuración en un archivo `compose.yaml`.

Ejemplo conceptual:

```yaml
services:
  oracle:
    image: local/oracle19c-se2:19.3.0
    ports:
      - "127.0.0.1:1521:1521"
    volumes:
      - oracle19_data:/opt/oracle/oradata
```

Y luego levantar todo mediante:

```bash
docker compose up -d
```

Para este proyecto se prefiere Compose porque deja el ambiente reproducible.

---

# 12. Dirección definitiva del proyecto según el jefe

Se descartó el DB Link hacia Desarrollo.

No queremos:

```text
Oracle Docker
    ↓ DB Link
GENERALIDADES de Desarrollo
```

Queremos:

```text
Oracle Docker
│
├── GENERALIDADES local
│
├── dependencias mínimas locales
│
└── esquema del desarrollador
```

La prueba ideal debe seguir funcionando incluso si el equipo no tiene conectividad con DEV/QA.

---

# 13. Inventario real de GENERALIDADES

Se consultó:

```sql
SELECT object_type, COUNT(*) cantidad
FROM all_objects
WHERE owner = 'GENERALIDADES'
GROUP BY object_type
ORDER BY object_type;
```

Resultado:

```text
OBJECT_TYPE     CANTIDAD
FUNCTION        6
INDEX           48
LOB             10
PACKAGE         47
PACKAGE BODY    45
PROCEDURE       4
SEQUENCE        16
SYNONYM         8
TABLE           40
TRIGGER         17
TYPE            3
VIEW            41
```

Tamaño aproximado:

```text
30.19 MB
```

Conclusión:

El tamaño es pequeño y muy manejable. El desafío principal no es almacenamiento, sino dependencias y orden correcto de instalación.

---

# 14. Dependencias externas detectadas de GENERALIDADES

Consulta realizada sobre dependencias encontró:

```text
GENERALIDADES.PKG_LOG
    → AUDITOR.LOG_SYSTEM (TABLE)

GENERALIDADES.PKG_TEST_REGISTRA_LOG
    → AUDITOR.LOG_SYSTEM (TABLE)

GENERALIDADES.PKG_PERSONA
    → AUDITOR.LOG_SYSTEM (TABLE)

GENERALIDADES.PKG_VISORES
    → AUDITOR.LOG_SYSTEM (TABLE)

GENERALIDADES.GETALL_LOG_SYSTEM
    → AUDITOR.LOG_SYSTEM (TABLE)

GENERALIDADES.PKG_LOG
    → AUDITOR.SEQ_LOG_SYSTEM_LOG_ID (SEQUENCE)

GENERALIDADES.GRL_ARCHIVO_VERSION_JSON_IDX
    → CTXSYS.CONTEXT_V2 (INDEXTYPE)

GENERALIDADES.SGU_APLICACION (SYNONYM)
    → SIGESUSTIC.SGU_APLICACION (TABLE)

GENERALIDADES.PKG_PARAMETRO
    → SIGESUSTIC.SGU_APLICACION (TABLE)

GENERALIDADES.PKG_PARAMETRO
    → SIGESUSTIC.SGU_SISTEMA (TABLE)
```

Arquitectura mínima actualmente inferida:

```text
DEMOPDB
│
├── AUDITOR
│   ├── LOG_SYSTEM
│   └── SEQ_LOG_SYSTEM_LOG_ID
│
├── SIGESUSTIC
│   ├── SGU_APLICACION
│   └── SGU_SISTEMA
│
├── GENERALIDADES
│
└── ESQUEMA_DEL_DESARROLLADOR
```

**Pero todavía hay que comprobar dependencias recursivas** de:

```text
AUDITOR.LOG_SYSTEM
AUDITOR.SEQ_LOG_SYSTEM_LOG_ID
SIGESUSTIC.SGU_APLICACION
SIGESUSTIC.SGU_SISTEMA
```

También hay que revisar:
- FKs de esas tablas;
- grants que recibe `GENERALIDADES`;
- sinónimos privados;
- posibles PUBLIC SYNONYMS;
- Oracle Text (`CTXSYS.CONTEXT_V2`);
- datos maestros mínimos requeridos.

---

# 15. Estrategia inicial considerada: Data Pump

Se evaluó `expdp/impdp`.

Data Pump permitiría:

```text
QA/DEV GENERALIDADES
       ↓ expdp
generalidades.dmp
       ↓ impdp
Docker DEMOPDB
       ↓
GENERALIDADES
```

Es válido, pero apareció una alternativa posiblemente mejor para esta PoC:

> El compañero de QA entregó los scripts SQL con los que se crea GENERALIDADES en QA.

Esto es interesante porque permite dejar la instalación versionada como código y reproducible.

Por ahora se priorizará revisar esos scripts antes de decidir si Data Pump sigue siendo necesario.

---

# 16. Scripts entregados por QA

El compañero de QA entregó varios archivos.

En esta conversación se recibió específicamente:

```text
MASTER GRL.sql
```

La intención parece ser que este archivo actúe como **script maestro/orquestador** que ejecuta múltiples scripts separados.

El archivo fue inspeccionado parcialmente.

## Encabezado observado

Contiene algo como:

```sql
DEFINE BASE_PATH_NO_VERSIONABLES =
"C:\Users\Camilo Donoso\Documents\TESTING\BBDD QA\GENERALIDADES\No versionables"

DEFINE BASE_PATH_VERSIONABLES =
"C:\Users\Camilo Donoso\Documents\TESTING\BBDD QA\GENERALIDADES\Versionables"
```

Después ejecuta numerosos archivos con `@`.

Ejemplos observados:

```text
GRL_ARCHIVO.sql
GRL_ARCHIVO_VERSION.sql
GRL_ATRIBUTO.sql
GRL_COMPONENTE.sql
GRL_DATO_ELEMENTO.sql
GRL_DIRECCION.sql
GRL_ELEMENTO.sql
GRL_PARAMETRO.sql
GRL_PERSONA.sql
GRL_REFERENCIA.sql
GRL_REFERENCIA_ITEM.sql
...
SEQUENCES.sql
TYPES.sql
```

Después carga packages versionables, por ejemplo:

```text
PKG_REFERENCIA_ITEM.sql
PKG_GRL_DATO_ELEMENTO.sql
PKG_GRL_SUBCOMPONENTE.sql
PKG_GRL_CONFIG.sql
PKG_VALIDACIONES.sql
PKG_REFERENCIA.sql
PKG_GRL_ATRIBUTO.sql
PKG_REFERENCIA_ROL.sql
PKG_PARAMETRO.sql
PKG_REFERENCIA_SISTEMA.sql
PKG_VISORES.sql
PKG_LOG.sql
PKG_GRL_ARCHIVO_VERSION.sql
PKG_VALIDATOR.sql
PKG_GRL_ARCHIVO_COMBINADO.sql
PKG_GRL_COMPONENTE.sql
PKG_GRL_ELEMENTO_PADRE.sql
PKG_GRL_ESTRUCTURA.sql
PKG_ESTRUCTURA_NEGOCIO.sql
PKG_UTILIDADES.sql
PKG_PERSONA.sql
PKG_GRL_ELEMENTO.sql
PKG_GRL_ARCHIVO.sql
```

Al final ejecuta un bloque PL/SQL que intenta recompilar `PACKAGE` y `PACKAGE BODY` inválidos hasta 5 veces.

---

# 17. Problemas detectados preliminarmente en MASTER GRL.sql

## 17.1 Rutas absolutas del computador del compañero

Actualmente usa:

```text
C:\Users\Camilo Donoso\Documents\TESTING\BBDD QA\GENERALIDADES\...
```

Eso NO servirá dentro del contenedor Linux.

Necesitamos convertirlo a rutas relativas o rutas Linux.

La solución ideal es que la carpeta completa de QA mantenga su estructura, por ejemplo:

```text
oracle19-poc/
└── setup/
    └── generalidades/
        ├── MASTER_GRL.sql
        ├── No versionables/
        │   └── ...
        └── Versionables/
            └── ...
```

Y que el MASTER utilice rutas relativas.

Ejemplo conceptual:

```sql
DEFINE BASE_PATH_NO_VERSIONABLES = "./No versionables"
DEFINE BASE_PATH_VERSIONABLES = "./Versionables"
```

o adaptar el mecanismo correctamente para SQL*Plus/SQLcl dentro del contenedor.

## 17.2 Posible inconsistencia/typo en variable

En el encabezado observado se define:

```sql
BASE_PATH_NO_VERSIONABLES
```

pero las referencias posteriores parecen utilizar:

```sql
&BASE_PATH_NO_VERSIONALES.
```

Es decir:

```text
NO_VERSIONABLES   ← definido
NO_VERSIONALES    ← usado
```

Falta `B` en las referencias.

Esto debe comprobarse y corregirse antes de ejecutar el MASTER.

Podría ser simplemente un typo del script exportado/copied.

## 17.3 El MASTER NO parece contener todos los objetos en sí

El MASTER referencia muchos archivos externos.

Por lo tanto:

```text
MASTER GRL.sql solo NO es suficiente.
```

Necesitamos la carpeta completa del compañero, incluyendo:

```text
No versionables/
Versionables/
```

y todos los `.sql` referenciados.

Esto encaja bien con la idea de abrir la carpeta desde la aplicación de ChatGPT para que pueda analizarse recursivamente.

---

# 18. Punto exacto en el que estamos

Estado:

```text
FASE 1 — Infraestructura Docker
✅ WSL 2 funcionando
✅ Docker Desktop funcionando
✅ Oracle 19c SE2 19.3 construido
✅ Oracle container healthy
✅ DEMOCDB creado
✅ DEMOPDB creado
✅ DataGrip conecta
✅ Charset coincide
✅ Persistencia comprobada

FASE 2 — GENERALIDADES
✅ Inventario de objetos
✅ Tamaño conocido (~30.19 MB)
✅ Dependencias externas principales detectadas
✅ QA entregó scripts de creación
✅ MASTER GRL.sql revisado preliminarmente

➡️ ESTAMOS AQUÍ:
Analizar la carpeta completa de scripts QA,
adaptarla a Docker/Linux,
resolver dependencias,
y ejecutar GENERALIDADES en una DEMOPDB de prueba.
```

Todavía NO se ha instalado GENERALIDADES en el Docker.

---

# 19. Qué debe hacer el siguiente chat/agente

Si tiene acceso a la carpeta completa de QA, debe proceder así.

## PASO A — Inventariar los archivos

Recorrer recursivamente la carpeta y listar:

```text
MASTER
No versionables/
Versionables/
otros scripts
```

Confirmar que existen todos los archivos mencionados por `MASTER GRL.sql`.

Detectar referencias rotas.

---

## PASO B — Analizar MASTER GRL.sql

Revisar:

1. Variables `DEFINE`.
2. Error `NO_VERSIONABLES` vs `NO_VERSIONALES`.
3. Rutas Windows absolutas.
4. Orden de ejecución.
5. `CONNECT`, `ALTER SESSION`, `ALTER PLUGGABLE DATABASE`, etc.
6. Usuario esperado al ejecutar.
7. Tablespaces esperados.
8. Grants.
9. Sinónimos.
10. Datos DML.
11. Dependencias `AUDITOR`.
12. Dependencias `SIGESUSTIC`.
13. Oracle Text.
14. Scripts que puedan requerir permisos SYS/SYSTEM.
15. Objetos que puedan tener nombres específicos de QA.

---

## PASO C — Determinar cómo se crea el usuario GENERALIDADES

Buscar en toda la carpeta:

```text
CREATE USER GENERALIDADES
ALTER USER GENERALIDADES
DEFAULT TABLESPACE
TEMPORARY TABLESPACE
QUOTA
GRANT CREATE SESSION
GRANT CREATE TABLE
GRANT CREATE PROCEDURE
...
```

Es posible que el MASTER asuma que `GENERALIDADES` ya existe.

Si es así, habrá que crear un script previo como:

```text
01_create_generalidades.sql
```

---

## PASO D — Revisar dependencias externas

Buscar globalmente:

```text
AUDITOR.
SIGESUSTIC.
CTXSYS.
@dblink
DATABASE LINK
```

En particular:

```text
AUDITOR.LOG_SYSTEM
AUDITOR.SEQ_LOG_SYSTEM_LOG_ID
SIGESUSTIC.SGU_APLICACION
SIGESUSTIC.SGU_SISTEMA
CTXSYS.CONTEXT_V2
```

Determinar si los scripts QA incluyen esas dependencias o si habrá que crear versiones mínimas.

---

## PASO E — Revisar sinónimos

Ya sabemos que `GENERALIDADES` tiene 8 sinónimos.

El agente debe detectar todos los:

```sql
CREATE SYNONYM
CREATE OR REPLACE SYNONYM
CREATE PUBLIC SYNONYM
```

y comprobar que sus destinos existan dentro del Docker.

No crear sinónimos apuntando accidentalmente a QA/DEV mediante DB Link.

---

## PASO F — No ejecutar todavía sobre el único volumen valioso

Antes de la primera ejecución masiva conviene elegir una estrategia segura.

Opciones:

1. Crear una segunda PoC/volumen descartable para pruebas.
2. Hacer un backup lógico del estado actual.
3. Luego experimentar con la instalación de GENERALIDADES.

No ejecutar `docker compose down -v` sin confirmar el volumen.

---

# 20. Estructura objetivo recomendada

Idealmente terminar con algo similar a:

```text
oracle19-poc/
├── compose.yaml
├── .env
├── README.md
│
└── setup/
    ├── 01_pre/
    │   ├── 01_tablespaces.sql
    │   ├── 02_auditor_min.sql
    │   ├── 03_sigesustic_min.sql
    │   └── 04_generalidades_user.sql
    │
    ├── 10_generalidades/
    │   ├── MASTER_GRL_DOCKER.sql
    │   ├── No versionables/
    │   │   └── ...
    │   └── Versionables/
    │       └── ...
    │
    └── 99_validation/
        └── validate_generalidades.sql
```

Otra opción es conservar exactamente la estructura entregada por QA y únicamente crear un MASTER adaptado para Docker.

---

# 21. Automatización futura

Oracle soporta scripts bajo:

```text
/opt/oracle/scripts/setup
```

La meta final podría ser una imagen derivada:

```text
local/oracle19c-se2-generalidades:19.3-grl1
```

que contenga los scripts de instalación de GENERALIDADES.

Conceptualmente:

```dockerfile
FROM local/oracle19c-se2:19.3.0

COPY setup/ /opt/oracle/scripts/setup/
```

Entonces:

```text
docker compose up -d
        ↓
Oracle crea DEMOCDB
        ↓
crea DEMOPDB
        ↓
ejecuta setup
        ↓
GENERALIDADES instalado
        ↓
entorno listo
```

La base física seguirá almacenándose en:

```text
/opt/oracle/oradata
```

mediante un volumen.

Por eso “empaquetado” debe entenderse como:

```text
Imagen Oracle
+
scripts institucionales dentro de la imagen/proyecto
+
proceso automático de inicialización
```

No como guardar manualmente datafiles vivos dentro de la imagen.

---

# 22. Primera ejecución: mejor manual antes de automatizar

Recomendación:

NO automatizar inmediatamente el MASTER de QA.

Primero:

```text
1. Adaptar scripts.
2. Ejecutarlos manualmente contra DEMOPDB.
3. Capturar errores.
4. Resolver dependencias.
5. Conseguir 0 objetos inválidos relevantes.
6. Probar un schema consumidor.
7. Recién después automatizar el setup.
```

Esto evita tener que recrear Oracle completo cada vez que falla un script en una línea intermedia.

---

# 23. Validaciones después de instalar GENERALIDADES

## Conteo

```sql
SELECT
    object_type,
    COUNT(*) AS cantidad
FROM dba_objects
WHERE owner = 'GENERALIDADES'
GROUP BY object_type
ORDER BY object_type;
```

Comparar con QA:

```text
FUNCTION        6
INDEX           48
LOB             10
PACKAGE         47
PACKAGE BODY    45
PROCEDURE       4
SEQUENCE        16
SYNONYM         8
TABLE           40
TRIGGER         17
TYPE            3
VIEW            41
```

## Objetos inválidos

```sql
SELECT
    object_type,
    object_name,
    status
FROM dba_objects
WHERE owner = 'GENERALIDADES'
  AND status <> 'VALID'
ORDER BY object_type, object_name;
```

## Errores de compilación

```sql
SELECT
    name,
    type,
    line,
    position,
    text
FROM dba_errors
WHERE owner = 'GENERALIDADES'
ORDER BY name, sequence;
```

## Recompilación

```sql
BEGIN
    UTL_RECOMP.RECOMP_SERIAL('GENERALIDADES');
END;
/
```

Después repetir validación.

---

# 24. Prueba funcional que debe hacerse después

Una vez `GENERALIDADES` esté válido, crear:

```text
APP_DEMO
```

y un package mínimo que use una librería real, por ejemplo:

```text
APP_DEMO.PKG_PRUEBA
        ↓
GENERALIDADES.PKG_VALIDATOR
```

o:

```text
APP_DEMO.PKG_PRUEBA
        ↓
GENERALIDADES.PKG_LOG
```

Eso demostrará que no solo “existen los objetos”, sino que un esquema externo realmente puede utilizar las librerías institucionales.

---

# 25. Prueba final de reproducibilidad

Cuando todo funcione manualmente:

1. Crear imagen/estructura reproducible.
2. Usar un volumen descartable.
3. Eliminar la base completa.
4. Levantar desde cero.
5. Esperar a que Oracle termine.
6. Verificar que GENERALIDADES fue instalado automáticamente.
7. Verificar objetos inválidos.
8. Crear/importar un schema consumidor.
9. Ejecutar prueba funcional.

Meta:

```text
Docker limpio
      ↓
docker compose up -d
      ↓
Oracle 19c SE2
      +
GENERALIDADES
      +
dependencias mínimas
      ↓
READY
      ↓
desarrollador agrega SU_ESQUEMA
```

---

# 26. Trabajo posterior: RU 19.31

No mezclar todavía la instalación de GENERALIDADES con el parche de Oracle.

Una vez resuelta la PoC en 19.3:

```text
19.3 PoC funcional
      ↓
obtener RU 19.31
      ↓
construir nueva imagen Oracle
      ↓
repetir instalación limpia GENERALIDADES
      ↓
ejecutar pruebas
      ↓
comparar con QA
```

Tag conceptual futuro:

```text
local/oracle19c-se2:19.31
```

o, si se empaqueta GENERALIDADES:

```text
local/oracle19c-se2-generalidades:19.31-grl1
```

---

# 27. Comandos útiles del entorno actual

Ver Oracle:

```bash
cd ~/oracle19-poc
docker compose ps
```

Logs:

```bash
docker compose logs -f oracle
```

Entrar al contenedor:

```bash
docker exec -it oracle19-poc bash
```

SQL*Plus como SYS dentro del contenedor:

```bash
sqlplus / as sysdba
```

Ver imágenes:

```bash
docker images
```

Ver volúmenes:

```bash
docker volume ls
```

Detener/recrear contenedor conservando volumen:

```bash
docker compose down
docker compose up -d
```

PELIGRO — elimina volumen:

```bash
docker compose down -v
```

---

# 28. Prompt recomendado para continuar desde ChatGPT Desktop

Puedes decirle al siguiente chat:

> Lee primero `CONTEXTO_ORACLE_DOCKER_POC.md` completo. Después inspecciona recursivamente la carpeta que contiene los scripts que me entregó QA, especialmente `MASTER GRL.sql`, `No versionables` y `Versionables`. No ejecutes todavía los scripts. Quiero que identifiques archivos faltantes, rutas absolutas Windows, errores de variables, orden de ejecución, creación del usuario GENERALIDADES, tablespaces, grants, sinónimos y dependencias con AUDITOR, SIGESUSTIC y CTXSYS. Luego propón cómo adaptar esa carpeta para ejecutarla de forma reproducible dentro de `DEMOPDB` en mi Oracle Docker. Conserva la estructura original siempre que sea posible y crea una versión Docker del MASTER en vez de modificar a ciegas los originales. Antes de cualquier comando destructivo, adviérteme explícitamente qué volumen/base se perdería.

---

# 29. Resumen corto del estado

```text
✅ WSL reparado
✅ Ubuntu / usuario seba
✅ Docker Desktop
✅ Oracle 19c SE2 19.3 construido
✅ Imagen: local/oracle19c-se2:19.3.0
✅ Container: oracle19-poc
✅ CDB: DEMOCDB
✅ PDB: DEMOPDB
✅ 1521 accesible
✅ DataGrip conecta
✅ AL32UTF8
✅ AL16UTF16
✅ Persistencia comprobada

✅ GENERALIDADES inventariado
✅ 30.19 MB
✅ dependencias principales conocidas
✅ scripts de QA disponibles

➡️ SIGUIENTE:
analizar carpeta completa QA + MASTER GRL,
adaptar rutas/orden/dependencias,
e instalar GENERALIDADES en DEMOPDB.
```
