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
