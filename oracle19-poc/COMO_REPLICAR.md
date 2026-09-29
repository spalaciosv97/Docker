# Cómo replicar este entorno

Explica en qué se convierte esto al final, y cómo llega a que
**cualquiera haga `docker compose up -d` y tenga Oracle + GENERALIDADES
listo**.

---

## Primero: aclarar qué es cada cosa

Hay dos contenedores dando vueltas y es fácil confundirlos.

| | `oracle19-poc` (puerto 1521) | `oracle19-lab` (puerto 1522) |
|---|---|---|
| Qué es | El Oracle vacío del primer experimento | El banco de pruebas de GENERALIDADES |
| Para qué sirvió | Probar que Oracle 19c SE2 corre en Docker, persiste y el charset coincide | Probar que los scripts de QA instalan bien |
| Qué tiene adentro | Una base de prueba sin valor real | GENERALIDADES + dependencias + datos |
| Se puede borrar | Sí | Sí |

**Ninguno de los dos es el producto final.**

### No se "mete" el lab dentro del original

Esa es la parte que suele confundir. El lab **no se fusiona** con el
`oracle19-poc` original ni se copia adentro. Los dos son andamios:

- `oracle19-poc` demostró la **FASE 1** (Oracle funciona en Docker).
  Ya cumplió; su volumen no contiene nada que valga la pena conservar.
- `oracle19-lab` demuestra la **FASE 2** (GENERALIDADES instala y
  funciona). También es desechable.

**El producto final es la receta, no la base.** Es decir: la imagen +
los scripts + el compose, de manera que la base se pueda **reconstruir
desde cero** cuando se quiera. Si el entregable fuera "este contenedor
que tengo andando", no sería reproducible: nadie más podría levantarlo.

De hecho, la prueba de que la PoC está terminada es justamente poder
**borrar todo y que se rearme solo**.

### Entonces, ¿por qué un lab aparte?

Por seguridad, nada más. Instalar 80 scripts de golpe sobre la única
base que funciona es pedir problemas: si algo queda a medias, hay que
adivinar qué quedó mal. Con un volumen descartable, un error se limpia
con un comando y se repite desde cero.

Cuando la instalación quede verde, **los dos contenedores se pueden
borrar** y se levanta el definitivo desde la receta.

---

## Hacia dónde va esto

```
HOY                        →   META
─────────────────────────      ────────────────────────────────
docker compose up -d           docker compose up -d
   (Oracle vacío)                 ↓
docker exec install.sh         Oracle arranca
   (instalación manual)           ↓
   ↓                           crea DEMOCDB / DEMOPDB
GENERALIDADES instalado           ↓
                               ejecuta el setup SOLO
                                  ↓
                               GENERALIDADES listo
                                  ↓
                               el dev agrega SU_ESQUEMA
```

La diferencia es que hoy hay un paso manual (`install.sh`) y la meta es
que ese paso lo haga Oracle solo al arrancar.

### Cómo se logra

La imagen oficial de Oracle ejecuta automáticamente todo lo que
encuentre en `/opt/oracle/scripts/setup` **la primera vez** que crea la
base. Basta con dejar ahí un script que llame a nuestra instalación.

Hay dos formas de entregarlo, y conviene entender el trade-off:

#### Opción A — Distribuir scripts + compose (recomendada)

Cada persona clona el repo y hace `docker compose up -d`. Oracle crea la
base y corre el setup solo.

- ✅ El repo pesa unos pocos MB. Va a Git sin problema.
- ✅ Se ve exactamente qué se instala; se puede revisar en un PR.
- ✅ Actualizar GENERALIDADES = cambiar unos `.sql`.
- ❌ El primer arranque tarda ~20-25 min (Oracle crea la base + instala).

#### Opción B — Distribuir una imagen ya construida

Se hornea la base ya instalada dentro de la imagen.

- ✅ Arranca en 2-3 min.
- ❌ La imagen pesa 10+ GB. Hay que subirla a un registry privado.
- ❌ Es una caja negra: no se ve qué tiene adentro.
- ❌ Oracle desaconseja meter datafiles vivos en una imagen.

**Recomendación: opción A.** Los 20 minutos se pagan una sola vez, y a
cambio queda algo auditable y versionable. Si el tiempo llegara a
molestar, la B se puede agregar después sin rehacer nada.

---

## Los pasos que faltan

### 1. ✅ Instalación en el lab — hecho

`install.sh` corre limpio: **0 errores en los tres logs y 0 objetos
inválidos**. Resultado:

```
FUNCTION 1 · INDEX 38 · PACKAGE 23 · PACKAGE BODY 22 · SEQUENCE 12
TABLE 27 · TRIGGER 5 · TYPE 3 · VIEW 14 · LOB 5
```

(Los conteos de `TABLE` e `INDEX` incluyen las tablas internas `DR$…`
que crea Oracle Text para el índice JSON.)

### 2. ✅ Un esquema externo la consume — hecho

`setup/99_validation/prueba_funcional.sql` crea `APP_DEMO` con un
package que llama a las librerías institucionales. Salida real:

```
PKG_UTILIDADES.TO_FLOAT           = 123,45
Comunas visibles desde APP_DEMO   = 349
Filas en AUDITOR.LOG_SYSTEM       = 1
==> Un esquema externo consumio GENERALIDADES OK
```

Eso es el objetivo del jefe cumplido: no solo existen los objetos, un
esquema nuevo los **usa** — llama funciones, lee vistas con datos
maestros y escribe en el log institucional que vive en otro esquema.

### 3. Automatizar el arranque

Crear un `autorun.sh` de una línea:

```bash
#!/bin/bash
exec bash /poc/install.sh
```

y montarlo en el compose donde Oracle lo busca:

```yaml
volumes:
  - ./autorun.sh:/opt/oracle/scripts/setup/autorun.sh:ro
```

La imagen oficial ejecuta todo lo que encuentre en
`/opt/oracle/scripts/setup` **solo la primera vez**, cuando crea la
base. En arranques posteriores detecta que ya existe y lo salta — que es
justo lo que se quiere.

Dos cosas a cuidar cuando se haga:

- `autorun.sh` debe tener finales de línea **LF**, no CRLF. Si se edita
  desde Windows, `bash` falla con un error críptico.
- El script corre como el usuario `oracle` dentro del contenedor, y
  `/poc/logs` tiene que ser escribible.

### 4. ✅ La prueba de fuego — hecha

```bash
docker compose -p oracle19-lab -f compose.lab.yaml down -v   # borra TODO
docker compose -p oracle19-lab -f compose.lab.yaml up -d     # desde cero
docker exec oracle19-lab bash /poc/install.sh
```

Resultado sobre un volumen recién creado, sin ninguna intervención
manual: **0 errores en los 4 logs, 0 objetos inválidos, exit code 0**, y
la prueba funcional pasando.

Lo único que falta para el objetivo final es que ese `docker exec` lo
haga Oracle solo (paso 3).

**No saltarse este paso ni darlo por hecho.** Al hacerlo por primera vez
aparecieron dos bugs de orden que una reinstalación sobre la base ya
usada escondía por completo: los `GRANT` a un usuario que aún no
existía, y 19 package bodies que no compilaban porque dependen de
sinónimos públicos creados más tarde. Los sinónimos públicos, además,
**sobreviven al `DROP USER`**, así que la segunda instalación siempre
sale mejor que la primera. Eso es exactamente lo que hay que evitar.

### 5. Recién ahí, el RU 19.31

Con la PoC cerrada en 19.3, se pide el Release Update al DBA, se
construye una imagen nueva y se repite la instalación limpia. **No
mezclar los dos problemas**: si algo falla, no se sabría si es el parche
o los scripts.

---

## Para el desarrollador que llegue después

Una vez terminado, alguien que quiera trabajar sobre esto hace:

```bash
git clone <repo>
cd oracle19-poc
docker compose up -d
# ~20 min la primera vez
```

Y se conecta con DataGrip a `127.0.0.1:1521`, Service Name `DEMOPDB`.

Para agregar su esquema, el patrón es el de
`99_validation/prueba_funcional.sql`:

```sql
CREATE USER MI_APP IDENTIFIED BY "...";
GRANT CONNECT, RESOURCE TO MI_APP;

-- Grants DIRECTOS sobre cada objeto, NO vía rol: al compilar PL/SQL
-- Oracle ignora los privilegios heredados de roles, y los packages
-- quedarían INVALID.
GRANT EXECUTE ON GENERALIDADES.PKG_UTILIDADES TO MI_APP;
GRANT SELECT  ON GENERALIDADES.GRL_REFERENCIA_ITEM TO MI_APP;
```

---

## Actualización: las tres imágenes pre-horneadas

> Lo de arriba describe el camino hasta la FASE 2. Después el jefe
> eligió la **opción B** (imagen pre-horneada, ver la bitácora), y hoy se
> construyen tres imágenes desde los mismos scripts de `setup/`:

```bash
./build.sh 1.0.0                 # oracle19c-grl            — solo la base
./build.sh 1.1.0 --ords          # oracle19c-grl-ords       — + ORDS, sin APEX
./build.sh 1.1.0 --ords-apex     # oracle19c-grl-ords-apex  — + ORDS + APEX runtime
```

La memoria de Oracle está **fijada** en los compose de build
(`INIT_SGA_SIZE=2055`, `INIT_PGA_SIZE=685`, lo mismo que tienen la 1.0.0
y la 1.1.0), así la imagen sale igual donde sea que se construya. En un
servidor compartido se limita además el contenedor (sin swap extra, salvo
`MEMSWAP_LIMIT`):

```bash
MEM_LIMIT=4g ./build.sh 1.0.0
```

### Construir en el servidor `docker-prod`

Mismos scripts, dos puntos de entrada en [`servidor/`](servidor/). No hay
una copia aparte del build: `build_servidor.sh` llama al mismo
`build.sh`, así la imagen sale igual en el notebook y en el servidor.

```bash
# 1. En el notebook (Git Bash o WSL), con todo commiteado:
bash servidor/subir_al_servidor.sh
#    código del último commit + imagen base + Java/ORDS exactos (solo si faltan)

# 2. En el servidor:
ssh docker-prod
cd ~/oracle19-poc && bash servidor/build_servidor.sh 1.1.0 --ords
#    = MEM_LIMIT=4g + nohup; no arranca si el lab está corriendo
```

El `.tar.gz` queda en `~/oracle19-poc/dist/` del servidor. Para traerlo:
`scp docker-prod:oracle19-poc/dist/<archivo>.tar.gz .`

**Lab en el servidor** (`servidor/lab/`): el `compose.yaml` que reciben
los compañeros, **sin tocar**, más `compose.servidor.yaml` encima
(nombre `oracle19-lab-ords`, 4 GB, `nofile`, puertos en `127.0.0.1`):

```bash
# en ~/oracle19-lab-ords/ del servidor: compose.yaml (de la carpeta
# distribuible) + servidor/lab/compose.servidor.yaml
docker compose -p oracle19-lab-ords -f compose.yaml -f compose.servidor.yaml up -d
```

Desde el notebook, por túnel: `ssh -N -L 1522:127.0.0.1:1521 -L 8080:127.0.0.1:8082 docker-prod`
y luego `localhost:1522` (DataGrip) y `http://localhost:8080/ords/...`.

Ojo en ese servidor: `autoheal` reinicia **cualquier** contenedor
*unhealthy* (`AUTOHEAL_CONTAINER_LABEL=all`), también los nuestros.

Las dos con ORDS necesitan antes, una sola vez (~10 min, desde WSL):

```bash
bash ords/descargar.sh       # Java 21, ORDS y APEX a ords/downloads/ (no versionado)
bash ords/construir_base.sh  # local/oracle19c-se2-ords:19.3.0 + prueba de humo
```

| | base | `--ords` | `--ords-apex` |
|---|---|---|---|
| Tiempo de build | ~30 min | ~35 min | ~55 min |
| Instalación | `install.sh` | `install.sh` + `install_ords.sh` | ídem, con `WITH_APEX=true` |
| Puertos del build | 1523 | 1524 / 8082 | 1525 / 8083 |
| Logs | `logs/` | `logs/ords/` | `logs/ords-apex/` |
| Gate antes de congelar | `INSTALL_OK` | + `ORDS_INSTALL_OK` + prueba HTTP | ídem |

La única diferencia entre las dos con ORDS es si APEX queda instalado
en la base. Por eso el endpoint `/ords/app_demo/v1/prueba-apex` es idéntico
en ambas, y `build.sh` exige un resultado distinto en cada una: **200**
con APEX, y **fallo con `PLS-00201 ... APEX_JSON`** sin APEX. Si la
variante sin APEX respondiera 200, el build aborta.

WSL tiene 6 GB de RAM en esta máquina: construir las variantes **de a
una**, no en paralelo.

---

## Cosas que se van a preguntar

**¿Y si QA cambia GENERALIDADES?** Se reemplazan los `.sql` de
`setup/10_generalidades/` y se vuelve a levantar desde cero. Por eso los
originales de QA se conservan sin tocar en `../GENERALIDADES/`: se puede
comparar la entrega nueva contra la vieja.

**¿Los datos son reales?** No. Son referencias y parámetros de
Desarrollo (comunas, países, tipos de dato). No hay datos personales.
Viven aislados en `30_data/` para poder reemplazarlos.

**¿Sirve para producción?** No, y no es el objetivo. Es un entorno de
desarrollo local: sin HA, sin backups, sin TLS, con contraseñas en
texto plano en el repo a propósito.

**¿Por qué 19.3 y no 19.31?** Ver la sección 5. Es deliberado.
