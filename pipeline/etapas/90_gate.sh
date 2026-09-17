#!/bin/bash
# Etapa 90 - Puerta de control integrada, bitacora y notificacion.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

MARCA="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
FALLIDAS=0

evaluar() {
  local nombre="$1" archivo="$2" bloquea="$3"
  local codigo; [ -f "$archivo" ] && codigo="$(cat "$archivo")" || codigo="sin-ejecutar"
  local estado
  if [ "$codigo" = "0" ]; then estado="PASA"; elif [ "$codigo" = "sin-ejecutar" ]; then estado="SIN EJECUTAR"; else estado="FALLA"; fi
  [ "$bloquea" = "si" ] && [ "$estado" != "PASA" ] && FALLIDAS=$((FALLIDAS+1))
  printf "  %-35s %s\n" "$nombre" "$estado"
  echo "${MARCA} etapa=\"${nombre}\" estado=${estado} bloquea=${bloquea}" >> reportes/audit.log
}

echo "=================================================="
echo " Etapa 90: puerta de control"
echo "=================================================="
evaluar "10 Secretos en el codigo"    "reportes/.10_exit" "si"
evaluar "20 Secretos en el historial" "reportes/.20_exit" "no"
evaluar "30 Dependencias (SCA)"       "reportes/.30_exit" "si"
evaluar "40 Codigo propio (SAST)"     "reportes/.40_exit" "si"
evaluar "50 Infraestructura (IaC)"    "reportes/.50_exit" "si"
evaluar "60 Imagenes de contenedor"   "reportes/.60_exit" "si"
evaluar "70 SBOM (evidencia)"         "reportes/.70_exit" "no"
evaluar "80 Pruebas dinamicas (DAST)" "reportes/.80_exit" "si"

echo ""
if [ "$FALLIDAS" -gt 0 ]; then
  echo "DESPLIEGUE BLOQUEADO ($FALLIDAS control(es) bloqueante(s) en rojo)"
  echo "${MARCA} resultado=BLOQUEADO etapas_fallidas=${FALLIDAS}" >> reportes/audit.log
  echo "${MARCA} [ALERTA] Pipeline BLOQUEADO: ${FALLIDAS} control(es) en rojo." >> reportes/notificaciones.log
  exit 1
else
  echo "DESPLIEGUE PERMITIDO"
  echo "${MARCA} resultado=PERMITIDO" >> reportes/audit.log
  echo "${MARCA} [OK] Pipeline en verde: listo para desplegar." >> reportes/notificaciones.log
  exit 0
fi
