# Respuesta al incidente — XSS reflejado en vista previa de reseñas

## Contención inmediata

Si esto se hubiera detectado ya en Producción (no en QA), la acción
inmediata sería **desactivar el endpoint nuevo con una bandera de
configuración**, sin necesidad de revertir todo el despliegue:

```python
VISTA_PREVIA_HABILITADA = os.environ.get("VISTA_PREVIA_HABILITADA", "false") == "true"

@vista_previa_bp.route("/moderacion/resenas/<int:resena_id>/vista-previa", methods=["POST"])
def vista_previa_resena(resena_id):
    if not VISTA_PREVIA_HABILITADA:
        return jsonify({"error": "funcionalidad temporalmente deshabilitada"}), 503
    ...
```

Esto detiene el sangrado en minutos (apagando la bandera, sin desplegar
código nuevo) mientras se prepara el arreglo real. No corrige la causa
raíz — el endpoint sigue teniendo la falla en el código, solo que nadie
puede alcanzarlo mientras la bandera está apagada.

## Prevención (el arreglo real)

Se corrigió la causa raíz en `formatear_texto_enriquecido()`
(`app/moderacion/vista_previa_resena.py`): el texto que escribe el usuario
ahora se escapa con `markupsafe.escape()` **antes** de aplicarle cualquier
formato propio (negritas, saltos de línea). Esto neutraliza cualquier
HTML/JavaScript que el usuario intente inyectar, sin afectar la
funcionalidad de formato que pidió el producto.

Además, se ajustó el pipeline (Etapa 40, SAST) para que bloquee por
categoría de riesgo (palabras clave como "injection", "xss") sin importar
la severidad que la regla de semgrep le asigne — evitando que una falla
de este tipo vuelva a pasar desapercibida por un umbral demasiado
permisivo.

Esta es la corrección que efectivamente se promovió a Producción — no la
bandera de contención, que solo habría sido un parche temporal.
