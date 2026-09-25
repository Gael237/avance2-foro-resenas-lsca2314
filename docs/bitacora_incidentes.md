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
