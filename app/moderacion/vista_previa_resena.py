"""
PARCHE - Nueva funcionalidad: vista previa con formato enriquecido
Tema: Foro y resenas

Producto pide: que el moderador vea la resena YA formateada (negritas,
saltos de linea, enlaces) antes de aprobarla, en vez de texto plano. Integra
este endpoint en tu servicio de moderacion.
"""
from flask import Blueprint, request, render_template_string
from markupsafe import escape

vista_previa_bp = Blueprint("vista_previa", __name__)

PLANTILLA = """
<div class="resena-preview">
  <h3>Vista previa de la resena #{{ resena_id }}</h3>
  <div class="contenido">{{ contenido_formateado | safe }}</div>
</div>
"""


def formatear_texto_enriquecido(texto_original):
    """Convierte marcado simple tipo **negrita** y saltos de linea a HTML.
    REMEDIACION (XSS - CWE-79): el texto del usuario se escapa PRIMERO con
    markupsafe.escape(), neutralizando cualquier HTML/JavaScript que haya
    intentado inyectar. Las etiquetas de formato propio (<b>, <br>) se
    agregan DESPUES, sobre el texto ya seguro -- por eso siguen funcionando
    aunque el usuario ya no pueda inyectar las suyas.
    """
    texto_seguro = str(escape(texto_original))
    formateado = texto_seguro.replace("\n", "<br>")
    while "**" in formateado:
        formateado = formateado.replace("**", "<b>", 1)
        formateado = formateado.replace("**", "</b>", 1)
    return formateado


@vista_previa_bp.route("/moderacion/resenas/<int:resena_id>/vista-previa", methods=["POST"])
def vista_previa_resena(resena_id):
    """Muestra al moderador la resena con el formato enriquecido aplicado."""
    contenido_original = request.form.get("contenido", "")
    contenido_formateado = formatear_texto_enriquecido(contenido_original)

    return render_template_string(
        PLANTILLA, resena_id=resena_id, contenido_formateado=contenido_formateado
    )
