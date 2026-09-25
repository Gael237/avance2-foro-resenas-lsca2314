# Clasificación del hallazgo — Entrega Final

## Resumen

El parche `vista_previa_resena.py` (funcionalidad de vista previa con
formato enriquecido para el moderador) introduce una vulnerabilidad de
Cross-Site Scripting (XSS) reflejado en el endpoint
`POST /moderacion/resenas/<resena_id>/vista-previa`.

## Ubicación exacta

**Archivo:** `app/moderacion/vista_previa_resena.py`

```python
def formatear_texto_enriquecido(texto_original):
    formateado = texto_original.replace("\n", "<br>")
    while "**" in formateado:
        formateado = formateado.replace("**", "<b>", 1)
        formateado = formateado.replace("**", "</b>", 1)
    return formateado
```

```python
PLANTILLA = """
<div class="resena-preview">
  <h3>Vista previa de la resena #{{ resena_id }}</h3>
  <div class="contenido">{{ contenido_formateado | safe }}</div>
</div>
"""
```

## Tipo de falla

**Cross-Site Scripting (XSS) reflejado — CWE-79** (Improper Neutralization
of Input During Web Page Generation).

El endpoint recibe `contenido` directamente de `request.form` (controlado
100% por quien hace la petición HTTP, sin ninguna validación de origen),
lo procesa con `formatear_texto_enriquecido()` (que solo transforma `\n`
y `**`, sin eliminar ni escapar ninguna etiqueta HTML), y lo inserta en la
plantilla con el filtro `| safe`. Ese filtro desactiva explícitamente el
auto-escaping que Jinja2 aplica por defecto a cualquier variable, lo cual
permite que cualquier HTML/JavaScript enviado por el usuario se renderice
como código real en el navegador de quien vea la vista previa (el
moderador).

## Severidad: Alta

**Justificación del impacto:** la vista previa la abre el **moderador**,
un rol con más privilegios que un usuario normal dentro del sistema. Un
script inyectado ahí podría robar su sesión (cookie de autenticación),
ejecutar acciones en su nombre (por ejemplo aprobar contenido sin que él
lo decida realmente), o redirigirlo a un sitio de phishing.

**Justificación de la facilidad de explotación:** no requiere ningún
conocimiento técnico avanzado ni condiciones especiales. Basta con escribir
una reseña que contenga una etiqueta como `<script>...</script>` en el
campo `contenido` del formulario — no hay ninguna validación, sanitización,
ni lista blanca de por medio que lo impida.

No se clasifica como Crítica porque no permite ejecución de código en el
servidor (no es RCE) ni acceso directo a la base de datos — el impacto se
limita al navegador de quien visualiza la vista previa, aunque ese impacto
puede escalar (robo de sesión de un rol privilegiado).

## ¿Falso positivo?

No. Se confirmó manualmente: al mandar `contenido` con una etiqueta HTML
(por ejemplo `<b>prueba</b>` o `<img src=x onerror=alert(1)>`), la
respuesta del endpoint la devuelve tal cual, sin escapar, lista para
ejecutarse en cualquier navegador que la reciba.

## ¿Qué encontró mi pipeline y qué no?

**Sí lo encontró:** la Etapa 40 (SAST, semgrep) marcó exactamente el
archivo y la línea correctos:

app/moderacion/vista_previa_resena.py
❯❱ python.flask.security.audit.render-template-string.render-template-string
Found a template created with string formatting. This is susceptible
to server-side template injection and cross-site scripting attacks.
Línea 36-38

**Por qué el pipeline no bloqueó de todas formas:** el umbral que definí
en el Avance 2 para la Etapa 40 solo bloquea con hallazgos de severidad
`ERROR` en semgrep (o `HIGH` en bandit). Este hallazgo salió clasificado
como `WARNING` por la regla de semgrep, así que no sumó al contador de
`$ERRORES` de mi script, y la etapa completa marcó "PASA" a pesar de que
la herramienta sí detectó el problema real.

**Corrección aplicada al pipeline:** se ajustó el umbral de la Etapa 40
para que también cuente como bloqueante cualquier hallazgo de semgrep que
contenga las palabras "injection" o "xss" en su mensaje, sin importar si
la severidad reportada es ERROR o WARNING — ver `docs/respuesta_incidente.md`
para el detalle de este cambio.
