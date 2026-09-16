"""Servicio de moderacion de contenido - Foro y Resenas."""
from flask import Flask, jsonify, request

app = Flask(__name__)

PALABRAS_PROHIBIDAS = {"estafa", "fraude", "basura", "spam"}
LONGITUD_MINIMA = 5

# Guarda los ultimos textos recibidos para detectar contenido duplicado
# (simplificacion consciente: en memoria, se pierde al reiniciar el
# contenedor; suficiente para el alcance de este proyecto).
HISTORIAL_RECIENTE = []
LIMITE_HISTORIAL = 50
UMBRAL_DUPLICADOS = 3


@app.route("/salud")
def salud():
    return jsonify({"estado": "ok"})


@app.route("/moderar", methods=["POST"])
def moderar():
    datos = request.get_json(silent=True) or {}
    texto = datos.get("texto", "").strip()

    if len(texto) < LONGITUD_MINIMA:
        return jsonify({"aprobado": False, "razon": "el comentario es demasiado corto"})

    texto_normalizado = texto.lower()
    for palabra in PALABRAS_PROHIBIDAS:
        if palabra in texto_normalizado:
            return jsonify({"aprobado": False, "razon": f"contiene la palabra prohibida '{palabra}'"})

    HISTORIAL_RECIENTE.append(texto_normalizado)
    if len(HISTORIAL_RECIENTE) > LIMITE_HISTORIAL:
        HISTORIAL_RECIENTE.pop(0)

    repeticiones = HISTORIAL_RECIENTE.count(texto_normalizado)
    if repeticiones >= UMBRAL_DUPLICADOS:
        return jsonify({"aprobado": False, "razon": "contenido duplicado (posible spam)"})

    return jsonify({"aprobado": True, "razon": "cumple las reglas de moderacion"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
