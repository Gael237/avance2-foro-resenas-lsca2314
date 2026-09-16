"""API del Foro y Resenas de Productos - Sistema de Catalogo Retail."""
import os
import secrets

import requests
from flask import Flask, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import create_engine, Column, Integer, String, Text, Boolean, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, relationship

app = Flask(__name__)

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///foro.db")
MODERACION_URL = os.environ.get("MODERACION_URL", "http://moderacion:5001")

engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)
Base = declarative_base()

# Tokens de sesion en memoria (simplificacion consciente para el alcance de
# este proyecto; en produccion se usaria JWT o un almacen de sesiones real).
TOKENS = {}


class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True)
    nombre_usuario = Column(String(80), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)


class Hilo(Base):
    __tablename__ = "hilos"
    id = Column(Integer, primary_key=True)
    producto = Column(String(120), nullable=False)
    titulo = Column(String(200), nullable=False)
    autor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    comentarios = relationship("Comentario", backref="hilo")


class Comentario(Base):
    __tablename__ = "comentarios"
    id = Column(Integer, primary_key=True)
    hilo_id = Column(Integer, ForeignKey("hilos.id"), nullable=False)
    autor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    texto = Column(Text, nullable=False)
    calificacion = Column(Integer, nullable=False)
    aprobado = Column(Boolean, default=False)


Base.metadata.create_all(engine)


def usuario_autenticado():
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None
    token = auth.split(" ", 1)[1]
    return TOKENS.get(token)


@app.route("/salud")
def salud():
    return jsonify({"estado": "ok"})


@app.route("/registro", methods=["POST"])
def registro():
    datos = request.get_json(silent=True) or {}
    nombre_usuario = datos.get("nombre_usuario", "")
    password = datos.get("password", "")
    if not nombre_usuario or not password:
        return jsonify({"error": "nombre_usuario y password son requeridos"}), 400

    sesion = Session()
    if sesion.query(Usuario).filter_by(nombre_usuario=nombre_usuario).first():
        sesion.close()
        return jsonify({"error": "ese nombre de usuario ya existe"}), 409

    usuario = Usuario(
        nombre_usuario=nombre_usuario,
        password_hash=generate_password_hash(password),
    )
    sesion.add(usuario)
    sesion.commit()
    sesion.close()
    return jsonify({"creado": nombre_usuario}), 201


@app.route("/login", methods=["POST"])
def login():
    datos = request.get_json(silent=True) or {}
    nombre_usuario = datos.get("nombre_usuario", "")
    password = datos.get("password", "")

    sesion = Session()
    usuario = sesion.query(Usuario).filter_by(nombre_usuario=nombre_usuario).first()
    sesion.close()

    if not usuario or not check_password_hash(usuario.password_hash, password):
        return jsonify({"error": "credenciales invalidas"}), 401

    token = secrets.token_hex(16)
    TOKENS[token] = usuario.id
    return jsonify({"token": token})


@app.route("/hilos", methods=["POST"])
def crear_hilo():
    autor_id = usuario_autenticado()
    if not autor_id:
        return jsonify({"error": "no autenticado"}), 401

    datos = request.get_json(silent=True) or {}
    producto = datos.get("producto", "")
    titulo = datos.get("titulo", "")
    if not producto or not titulo:
        return jsonify({"error": "producto y titulo son requeridos"}), 400

    sesion = Session()
    hilo = Hilo(producto=producto, titulo=titulo, autor_id=autor_id)
    sesion.add(hilo)
    sesion.commit()
    hilo_id = hilo.id
    sesion.close()
    return jsonify({"id": hilo_id, "producto": producto, "titulo": titulo}), 201


@app.route("/hilos", methods=["GET"])
def listar_hilos():
    sesion = Session()
    hilos = sesion.query(Hilo).all()
    resultado = [{"id": h.id, "producto": h.producto, "titulo": h.titulo} for h in hilos]
    sesion.close()
    return jsonify(resultado)


@app.route("/hilos/<int:hilo_id>/comentarios", methods=["POST"])
def crear_comentario(hilo_id):
    autor_id = usuario_autenticado()
    if not autor_id:
        return jsonify({"error": "no autenticado"}), 401

    datos = request.get_json(silent=True) or {}
    texto = datos.get("texto", "")
    calificacion = datos.get("calificacion", 0)

    try:
        respuesta_moderacion = requests.post(
            f"{MODERACION_URL}/moderar", json={"texto": texto}, timeout=5
        )
        resultado_moderacion = respuesta_moderacion.json()
    except requests.exceptions.RequestException:
        return jsonify({"error": "el servicio de moderacion no esta disponible"}), 503

    aprobado = resultado_moderacion.get("aprobado", False)

    sesion = Session()
    comentario = Comentario(
        hilo_id=hilo_id,
        autor_id=autor_id,
        texto=texto,
        calificacion=calificacion,
        aprobado=aprobado,
    )
    sesion.add(comentario)
    sesion.commit()
    sesion.close()

    return jsonify({
        "aprobado": aprobado,
        "razon": resultado_moderacion.get("razon", ""),
    }), 201 if aprobado else 200


@app.route("/hilos/<int:hilo_id>/comentarios", methods=["GET"])
def listar_comentarios(hilo_id):
    sesion = Session()
    comentarios = (
        sesion.query(Comentario)
        .filter_by(hilo_id=hilo_id, aprobado=True)
        .all()
    )
    resultado = [
        {"id": c.id, "texto": c.texto, "calificacion": c.calificacion}
        for c in comentarios
    ]
    sesion.close()
    return jsonify(resultado)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
