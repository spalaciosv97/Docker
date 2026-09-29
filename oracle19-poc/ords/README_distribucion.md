# Oracle 19c + GENERALIDADES + ORDS@@TITULO@@

La misma base Oracle 19c SE2 de la versión 1.0.0, con `GENERALIDADES`
**ya instalado**, más **ORDS** (Oracle REST Data Services) instalado,
configurado y levantándose solo: la base queda disponible como API REST
en el puerto 8080. No depende de la VPN, ni de Desarrollo, ni de QA.

> **Esta imagen NO trae APEX, a propósito.** ORDS y APEX son dos
> productos distintos: instalar ORDS no instala APEX. Por eso los
> endpoints escritos al estilo institucional, que arman el JSON con
> `apex_json`, aquí **no funcionan**. El endpoint `/prueba-apex` existe
> justamente para mostrarlo. Los endpoints nuevos se escriben con JSON
> nativo de Oracle, como `/prueba`.

---

## Las imágenes

Son líneas paralelas, no versiones sucesivas: cada una sirve para algo
distinto y pueden convivir en la misma máquina.

| Imagen | ORDS | APEX | Para qué |
|---|---|---|---|
| `oracle19c-grl:1.0.0` | — | — | solo la base, por SQL |
| `oracle19c-grl-ords:1.1.0` | ✔ | — | APIs REST, sin `apex_json` |

**Esta carpeta es `@@IMAGEN@@`.**

Existe además una variante con APEX runtime (`oracle19c-grl-ords-apex`)
para correr endpoints escritos con `apex_json`. **No se reparte por
ahora**, pero está resuelta en los scripts del proyecto y se construye
con un comando si llega a hacer falta.

---

## Qué trae adentro

| | |
|---|---|
| Oracle Database | 19c Standard Edition 2 (19.3), `AL32UTF8` |
| `GENERALIDADES` | 23 packages, 14 vistas, 19 tablas, secuencias, tipos y triggers |
| Datos maestros | referencias, 215 países, 349 comunas, parámetros |
| Personas | **1000 registros ficticios generados** |
| `APP_DEMO` | esquema de ejemplo, **publicado por REST** en `/ords/app_demo/` |
| ORDS | @@VERSION_ORDS@@, en el puerto 8080, con Database Actions |
| APEX | @@FILA_APEX@@ |

---

## Primera vez

Los pasos detallados, con la verificación del archivo, están en
`LEEME_PRIMERO.txt`. En corto:

```powershell
docker load -i @@ARCHIVO@@
docker compose up -d
docker compose logs -f      # esperar "DATABASE IS READY TO USE!"
```

**ORDS responde 30-60 segundos después** de ese mensaje. El contenedor
aparece `healthy` en cuanto la base está lista, sin esperar a ORDS, a
propósito: así un problema de ORDS nunca bloquea el acceso a la base.

---

## Probar que funciona

En el navegador:

| URL | Debe mostrar |
|---|---|
| http://localhost:8080/ords/app_demo/v1/prueba | `{"data":{"comunas":349,"personas":1000},"status":"OK"}` |
| http://localhost:8080/ords/app_demo/v1/prueba-apex | @@RESULTADO_PRUEBA_APEX@@ |

Los dos endpoints viven en `APP_DEMO`, consultan `GENERALIDADES` y son
**el mismo bloque PL/SQL**, con el mismo `owa_util` y la misma forma de
respuesta. Lo único que cambia son las líneas que arman el JSON:

| `/prueba` — JSON nativo de Oracle | `/prueba-apex` — estilo institucional |
|---|---|
| `l_resp := JSON_OBJECT_T();` | `apex_json.open_object;` |
| `l_data.put('comunas', l_comunas);` | `apex_json.write('comunas', l_comunas);` |
| `htp.p(l_resp.to_string);` | `apex_json.close_object;` |

`JSON_OBJECT_T` viene con la base de datos. `apex_json` viene con APEX,
que es un producto aparte. Para ver el código completo: Database
Actions → menú ☰ → **REST** → *Modules* → `demo.v1`.

---

## Database Actions (la consola web)

http://localhost:8080/ords/sql-developer — entrar con `APP_DEMO` /
`App_Demo_2026`. No hace falta tocar *Avanzado*: el alias REST de
`APP_DEMO` es `app_demo`, igual al usuario.

Si habilitas tu propio esquema con un alias **distinto** a su nombre,
al entrar tendrás que escribir ese alias en *Avanzado → Ruta*; si no,
Database Actions responde "Credenciales no válidas" aunque la
contraseña esté bien.

Sirve para consultar tablas y correr SQL desde el navegador, sin
instalar nada. Solo entran los esquemas **habilitados para REST**
(ver abajo).

---

## Publicar endpoints de tu propio esquema

Conectado **como tu esquema** (no hace falta ser SYS):

```sql
BEGIN
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_schema              => 'MI_APP',
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'mi_app',
      p_auto_rest_auth      => FALSE);

  ORDS.DEFINE_MODULE(
      p_module_name => 'mi_app.v1',
      p_base_path   => '/v1/');

  ORDS.DEFINE_TEMPLATE(
      p_module_name => 'mi_app.v1',
      p_pattern     => 'comunas');

  ORDS.DEFINE_HANDLER(
      p_module_name => 'mi_app.v1',
      p_pattern     => 'comunas',
      p_method      => 'GET',
      p_source_type => ORDS.source_type_collection_feed,
      p_source      => 'SELECT * FROM GENERALIDADES.GRL_COMUNAS_VW');
  COMMIT;
END;
/
```

Queda en http://localhost:8080/ords/mi_app/v1/comunas. Tu esquema
necesita `GRANT SELECT` **directo** sobre lo que consulte de
`GENERALIDADES`, igual que para PL/SQL.

Los errores de un handler se ven en la misma respuesta HTTP (la imagen
trae `debug.printDebugToScreen` activado, porque es un entorno de
desarrollo). Busca el `ORA-` o `PLS-` dentro del campo `stackTrace`.

### Si tu handler usa `PKG_UTILIDADES.TO_FLOAT`

Las sesiones de ORDS **no** tienen coma decimal, así que `TO_FLOAT`
devuelve `NULL` sin avisar, igual que en cualquier sesión sin el ajuste.
Dentro de un handler PL/SQL, antes de llamarla:

```sql
EXECUTE IMMEDIATE q'~ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.'~';
```

---

## Conectarse a la base

Igual que en la 1.0.0:

```
Host: 127.0.0.1    Puerto: 1521    Service Name: DEMOPDB   (NO SID)
```

| Usuario | Contraseña | Para qué |
|---|---|---|
| `GENERALIDADES` | `Grl_Poc_2026` | el esquema institucional |
| `APP_DEMO` | `App_Demo_2026` | el ejemplo; también entra a Database Actions |
| `SYS` (as SYSDBA) | `Oracle_Poc_2026` | administración |

Y el ajuste de sesión que necesita `TO_FLOAT`:
`ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';`

---

## Manejar ORDS a mano

```bash
# Ver el log
docker exec @@CONTENEDOR@@ tail -f /opt/oracle/ords/logs/ords.log

# Reiniciarlo sin reiniciar la base
docker exec @@CONTENEDOR@@ bash /opt/oracle/ords/bin/stop_ords.sh
docker exec @@CONTENEDOR@@ bash /opt/oracle/scripts/startup/50_ords.sh
```

---

## Convivir con las otras imágenes

Cada carpeta usa su propio contenedor y su propio volumen, así que los
datos no se mezclan. Lo único que choca son los puertos si levantas dos
a la vez: cambia `DB_PORT` y/o `ORDS_PORT` en el `.env` de una de ellas.

---

## Actualizar a una versión nueva

Igual que en la 1.0.0, y por el mismo motivo: Docker rellena el volumen
con la imagen **solo si está vacío**.

```bash
./exportar_mi_esquema.sh MI_APP      # 1. respaldar lo tuyo
docker load -i <archivo nuevo>        # 2. cargar la imagen nueva
#                                       3. cambiar IMAGE_VERSION en .env
docker compose down -v                # 4. botar contenedor Y volumen
docker compose up -d                  # 5. levantar con volumen nuevo
./importar_mi_esquema.sh MI_APP       # 6. devolver lo tuyo
```

> **`down -v` borra la base entera.** Lo que no hayas exportado se pierde.
> Los módulos REST de tu esquema viven en `ORDS_METADATA`, no en tu
> esquema, así que **el export no los respalda**: guarda el script con
> tus `ORDS.DEFINE_*` y vuelve a correrlo después del import.

---

## Problemas frecuentes

**`/ords/...` no responde (conexión rechazada).** ORDS todavía está
arrancando: tarda 30-60 s después de `DATABASE IS READY TO USE!`. Si
sigue así después de 2 minutos, mira el log (ver *Manejar ORDS a mano*).

**Responde 571 `DatabaseConnectionError`.** ORDS quedó con el pool en
error y no reintenta solo. Reinícialo (ver *Manejar ORDS a mano*).

**Responde 404 en todo `/ords`.** Probablemente estás usando un volumen
de una versión anterior, que no tiene ORDS instalado. Falta el
`down -v` (ver *Actualizar*).

**`docker compose up` dice que el puerto 8080 (o 1521) está ocupado.**
Cambia `ORDS_PORT` (o `DB_PORT`) en el `.env`.

**Mi endpoint falla con `PLS-00201: identifier 'APEX_JSON...' must be
declared`.** Es lo esperado: APEX no está instalado. Arma el JSON con
`JSON_OBJECT_T` (como `/prueba`), con las funciones SQL `JSON_OBJECT` /
`JSON_ARRAYAGG`, o deja que ORDS lo arme solo con
`source_type_collection_feed`. Ojo: `ORDS.DEFINE_HANDLER` no avisa
nada, porque ORDS guarda el bloque como texto y recién lo compila
cuando llega la petición.

**`TO_FLOAT` me devuelve `NULL`.** Falta el ajuste de
`NLS_NUMERIC_CHARACTERS` (en la sesión, o dentro del handler).

---

## Qué NO es esto

Un entorno de desarrollo local y descartable. Los endpoints son
**anónimos**, las contraseñas están escritas en el `.env` a propósito y
los errores se muestran completos en la respuesta. Por eso los puertos
solo escuchan en `127.0.0.1`: **no lo expongas a la red** ni lo uses
para nada que importe.
