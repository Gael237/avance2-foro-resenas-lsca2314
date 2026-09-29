# Bitácora de incidentes técnicos - Entrega Final

Registro de cualquier error real encontrado durante el proceso (versiones,
dependencias, paquetes, configuración, etc.), independientemente de si es
la falla de seguridad que se pide encontrar o un tropiezo técnico aparte.

## Incidente 1: contenedor de moderación no levanta tras aplicar el parche

- **Qué pasó:** al correr el pipeline (Etapa 80, DAST), la conexión al
  puerto 5001 fue rechazada. El contenedor `moderacion` no aparecía ni
  siquiera en `docker compose ps`.
- **Cómo se diagnosticó:** se revisó `docker compose logs moderacion`, y
  se confirmó que el Dockerfile solo copia `moderador.py` con
  `COPY moderador.py .`, sin incluir el nuevo archivo `vista_previa_resena.py`
  que el parche agrega. Al intentar `from vista_previa_resena import
  vista_previa_bp`, Python no encuentra el módulo dentro del contenedor.
- **Cómo se resolvió:** se agregó `COPY vista_previa_resena.py .` al
  Dockerfile de moderación, junto a la línea que ya copiaba `moderador.py`.

## Incidente 2: la remediación del XSS no funcionó al primer intento

- **Qué pasó:** después de agregar `markupsafe.escape()` para remediar el
  XSS (CWE-79), la prueba manual con `<script>alert(1)</script>` seguía
  devolviendo la etiqueta sin escapar en la respuesta del endpoint.
- **Cómo se diagnosticó:** se verificó que el archivo en disco y dentro
  del contenedor tenían el cambio (`grep escape`, `docker exec ... cat`),
  se reconstruyó sin caché para descartar un problema de Docker
  (`docker compose build --no-cache`), y solo entonces se revisó la lógica
  línea por línea. Se encontró que la variable `texto_seguro` (ya escapada)
  se calculaba pero nunca se usaba: la línea siguiente seguía operando
  sobre `texto_original` (el texto sin escapar) por un error de copiado.
- **Cómo se resolvió:** se corrigió la línea
  `formateado = texto_original.replace(...)` para que usara
  `texto_seguro.replace(...)` en su lugar. Se volvió a probar manualmente
  y se confirmó que el escapado ya funcionaba (`&lt;script&gt;...`).
- **Lección:** declarar una variable "segura" no basta si el resto del
  código no la usa de verdad. Vale la pena probar manualmente el resultado
  real, no solo confiar en que el cambio "se ve correcto" al leerlo.

## Incidente 3: `nosemgrep` no funcionó en el primer intento

- **Qué pasó:** tras remediar el XSS, semgrep seguía marcando el mismo
  hallazgo de `render-template-string` como falso positivo justificado,
  aunque se había agregado un comentario `# nosemgrep` en la línea anterior
  a la del hallazgo.
- **Cómo se diagnosticó:** se confirmó revisando la documentación de
  semgrep que el comentario `# nosemgrep` debe ir en la MISMA línea donde
  se reporta el hallazgo, no en una línea de comentario separada arriba.
- **Cómo se resolvió:** se movió `# nosemgrep: <regla>` al final de la
  línea `return render_template_string(  # nosemgrep: ...`, dejando el
  comentario explicativo largo en las líneas de arriba (para que un
  lector humano vea la justificación) y el marcador técnico exacto en la
  línea que semgrep evalúa.

## Incidente 4: la interfaz web no cargaba desde el navegador

- **Qué pasó:** al agregar una interfaz web (`app/api/static/index.html`)
  para grabar los clips de la presentación, la página no cargaba al
  abrir `http://<IP-publica>:5000/` desde el navegador, aunque `curl
  http://localhost:5000/` sí funcionaba correctamente dentro de la propia
  instancia.
- **Cómo se diagnosticó:** se revisaron las reglas de entrada del security
  group de la instancia de QA (`sg-08bb0403cd54b7be9`) con
  `aws ec2 describe-security-groups`, encontrando que solo tenía abiertos
  los puertos 22, 8000 y 8080 — nunca se había abierto el 5000 ni el 5001,
  porque hasta ahora la aplicación solo se había probado desde dentro de
  la misma instancia (`localhost`), nunca desde un navegador externo.
- **Cómo se resolvió:** se agregaron 2 reglas de entrada nuevas al
  security group, autorizando tráfico TCP en los puertos 5000 y 5001
  desde cualquier origen (`0.0.0.0/0`), ya que a diferencia del acceso a
  RDS (restringido por diseño), esta interfaz está pensada para ser
  accesible públicamente como cualquier aplicación web de demostración.
- **Nota de credenciales:** también fue necesario renovar las credenciales
  de AWS Academy (habían expirado, error `RequestExpired`) antes de poder
  consultar el security group — recordatorio de que las credenciales
  temporales duran solo 3-4 horas.

## Incidente 5: columna nueva no se creaba automáticamente en RDS

- **Qué pasó:** al agregar el campo `imagen_key` al modelo `Hilo` para
  soportar subida de imágenes a S3, la creación de un hilo con imagen
  fallaba con `UndefinedColumn: column "imagen_key" of relation "hilos"
  does not exist`.
- **Cómo se diagnosticó:** se revisó el log del contenedor API
  (`docker compose logs api`), confirmando que el error era de SQL, no de
  S3 — de hecho la subida a S3 ya había funcionado antes de que fallara el
  INSERT en la base de datos.
- **Cómo se resolvió:** `Base.metadata.create_all(engine)` de SQLAlchemy
  solo crea tablas nuevas, nunca modifica tablas existentes. Como la tabla
  `hilos` ya existía desde el Día 2, hubo que agregar la columna
  manualmente con `ALTER TABLE hilos ADD COLUMN IF NOT EXISTS imagen_key
  VARCHAR(255);` directamente en RDS vía `psql`.
- **Lección:** cambiar un modelo de SQLAlchemy no migra automáticamente
  una base de datos que ya tiene datos; en un proyecto real se usaría una
  herramienta de migraciones (como Alembic) para manejar esto de forma
  versionada, en vez de un ALTER TABLE manual.


## Incidente 6: la imagen del comentario no se veía en el frontend

- **Qué pasó:** después de agregar soporte de imágenes a los comentarios
  (campo `imagen_key`, endpoint `/comentarios/<id>/imagen`, y el campo
  `tiene_imagen` en la respuesta de `listar_comentarios`), la interfaz web
  no mostraba el botón "Ver imagen" para comentarios que sí tenían una
  imagen adjunta.
- **Cómo se diagnosticó:** se probó directamente con `curl
  http://localhost:5000/hilos/9/comentarios` y se confirmó que la
  respuesta JSON no incluía el campo `tiene_imagen` en absoluto — ni
  siquiera como `false`. Se verificó dentro del contenedor en ejecución
  con `docker exec ... grep -A8 "def listar_comentarios" api.py` y se
  confirmó que el contenedor seguía corriendo la versión anterior de la
  función, sin el campo nuevo.
- **Cómo se resolvió:** aunque el archivo en disco (`app/api/api.py`) ya
  tenía el cambio correcto (confirmado con `grep` fuera del contenedor),
  un primer intento de `docker compose build --no-cache api` seguido de
  `up -d` no reflejó el cambio. Se repitió el ciclo completo
  (`down` → `build --no-cache` de ambos servicios → `up -d`), y esta vez
  sí se verificó línea por línea dentro del contenedor antes de probar
  con curl, confirmando que el código nuevo ya estaba presente.
- **Lección:** cuando un cambio "no aparece" después de reconstruir, no
  basta con confiar en que el build salió sin errores — conviene verificar
  explícitamente el contenido real dentro del contenedor en ejecución
  (`docker exec ... cat/grep archivo`) antes de seguir depurando la lógica
  de la aplicación, ya que el problema puede estar en el propio ciclo de
  construcción/despliegue, no en el código.
