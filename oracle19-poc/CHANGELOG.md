# Registro de versiones de la imagen

Cada entrada corresponde a un `oracle19c-grl-<versión>.tar.gz`.

Cuando publiques una versión nueva, copia esta sección junto al archivo
para que quien la reciba sepa qué cambió y si necesita respaldar su
esquema antes de actualizar.

Numeración:

- **Parche** (`1.0.1`) — corrección de scripts, mismo contenido lógico.
- **Menor** (`1.1.0`) — se agrega un esquema o cambian los datos.
- **Mayor** (`2.0.0`) — cambia la versión de Oracle (p. ej. el RU 19.31).

---

## 1.1.0-ords — 2026-09-28

Imagen **nueva y paralela** a la 1.0.0: `oracle19c-grl-ords:1.1.0`. No
reemplaza a la 1.0.0; las dos se pueden usar y conviven en la misma
máquina (contenedor y volumen con nombre propio).

**Contenido**

- Todo lo de la 1.0.0, instalado con los mismos scripts.
- **ORDS 26.2.3** (Oracle REST Data Services), sobre Java 21 (Temurin),
  en el puerto 8080. Se levanta solo en cada arranque del contenedor.
- `APP_DEMO` habilitado para REST con el alias `app_demo`, y dos
  endpoints de prueba que son el mismo bloque PL/SQL:
  - `GET /ords/app_demo/v1/prueba` — JSON nativo (`JSON_OBJECT_T`).
    Responde `{"data":{"comunas":349,"personas":1000},"status":"OK"}`.
  - `GET /ords/app_demo/v1/prueba-apex` — con `apex_json`, al estilo de
    los endpoints institucionales. **Falla a propósito** con
    `PLS-00201: identifier 'APEX_JSON.OPEN_OBJECT' must be declared`.
- Database Actions en `/ords/sql-developer` (usuario `APP_DEMO`).

**Notas**

- **No trae APEX.** ORDS y APEX son productos distintos; esta imagen
  deja a la vista que sin APEX los handlers con `apex_json` no compilan.
  La variante con APEX runtime está resuelta en los scripts
  (`./build.sh 1.1.0 --ords-apex`) pero no se reparte por ahora.
- Los errores de los handlers se muestran completos en la respuesta HTTP
  (`debug.printDebugToScreen`), y los endpoints son anónimos: entorno
  local, **no exponer a la red**.
- Arranque: la base en ~30 s, ORDS ~20 s después. El primer arranque
  tarda ~2 min porque Docker copia los datafiles al volumen nuevo.

**Al actualizar desde la 1.0.0**

No se actualiza: es otra imagen, en otra carpeta y con otro volumen. Tu
base de la 1.0.0 no se toca. Si quieres llevar tu esquema, usa
`exportar_mi_esquema.sh` en la carpeta de la 1.0.0, copia el `.dmp`
de su `dump/` al `dump/` de esta carpeta, y corre
`importar_mi_esquema.sh` acá. Los módulos REST no viajan en
el export (viven en `ORDS_METADATA`): guarda tu script de
`ORDS.DEFINE_*` y vuelve a correrlo.

---

## 1.0.0 — 2026-08-26

Primera versión distribuible.

**Contenido**

- Oracle Database 19c Standard Edition 2 (19.3.0), `AL32UTF8` /
  `AL16UTF16`, igual que el ambiente institucional.
- `GENERALIDADES`: 23 packages con sus bodies, 14 vistas, 19 tablas,
  12 secuencias, 5 triggers, 3 tipos, 38 índices. Cero objetos
  inválidos.
- Dependencias mínimas: `AUDITOR` (`LOG_SYSTEM` + secuencia) y
  `SIGESUSTIC` (`SGU_SISTEMA`, `SGU_APLICACION`, `SGU_USUARIO`).
- Datos maestros: 113 referencias, 1203 ítems (215 países, 349 comunas),
  23 parámetros.
- **1000 personas ficticias generadas** en `GRL_PERSONA`, con sus datos
  de contacto y direcciones.
- `APP_DEMO`: esquema de ejemplo que consume las librerías
  institucionales.

**Notas**

- Los datos de personas son sintéticos. Ninguno proviene de Desarrollo.
- Arranque: 1-3 min. Imagen ~12 GB, volumen ~3 GB.

**Al actualizar desde una versión anterior**

No aplica, es la primera.
