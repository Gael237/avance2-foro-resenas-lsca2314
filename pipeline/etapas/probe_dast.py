"""Pruebas dinamicas contra la API del Foro y el servicio de Moderacion."""
import sys
import time

import requests

BASE_API = "http://127.0.0.1:5000"
BASE_MOD = "http://127.0.0.1:5001"
CRITICAS = []


def registrar(nombre, ok, detalle):
    print(f"  [{'PASA' if ok else 'FALLA'}] {nombre}: {detalle}")
    CRITICAS.append(ok)


def main():
    r = requests.get(f"{BASE_API}/salud", timeout=5)
    registrar("API en linea", r.status_code == 200, f"/salud -> {r.status_code}")

    r2 = requests.get(f"{BASE_MOD}/salud", timeout=5)
    registrar("Moderacion en linea", r2.status_code == 200, f"/salud -> {r2.status_code}")

    usuario = f"probe_dast_{int(time.time())}"
    r3 = requests.post(f"{BASE_API}/registro", json={"nombre_usuario": usuario, "password": "clave123"}, timeout=5)
    registrar("Registro funciona", r3.status_code == 201, f"POST /registro -> {r3.status_code}")

    r4 = requests.post(f"{BASE_API}/login", json={"nombre_usuario": usuario, "password": "clave123"}, timeout=5)
    token = r4.json().get("token") if r4.status_code == 200 else None
    registrar("Login funciona", token is not None, f"POST /login -> {r4.status_code}")

    r5 = requests.post(f"{BASE_API}/login", json={"nombre_usuario": usuario, "password": "clave_incorrecta"}, timeout=5)
    registrar("Login rechaza password incorrecta", r5.status_code == 401, f"POST /login (mala) -> {r5.status_code}")

    r6 = requests.post(f"{BASE_API}/hilos", json={"producto": "x", "titulo": "y"}, timeout=5)
    registrar("Hilos exige autenticacion", r6.status_code == 401, f"POST /hilos sin token -> {r6.status_code}")

    fallidas = CRITICAS.count(False)
    print(f"\n  Pruebas fallidas: {fallidas}")
    return 1 if fallidas else 0


if __name__ == "__main__":
    sys.exit(main())
