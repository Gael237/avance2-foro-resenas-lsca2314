#!/bin/bash
# Etapa 80 - Pruebas dinamicas contra la app real (via docker compose).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes
# shellcheck disable=SC1091
source venv/bin/activate

echo "== Etapa 80: DAST sobre la app en ejecucion =="
docker compose up -d --build > reportes/80_compose.log 2>&1

LISTA=0
for _ in $(seq 1 20); do
  if curl -s -o /dev/null "http://127.0.0.1:5000/salud" 2>/dev/null; then LISTA=1; break; fi
  sleep 1
done

if [ "$LISTA" -eq 0 ]; then
  echo "  La app no levanto. Revisa reportes/80_compose.log"
  docker compose logs >> reportes/80_compose.log 2>&1
  echo "1" > reportes/.80_exit
  exit 1
fi

python3 pipeline/etapas/probe_dast.py > reportes/80_dast.txt 2>&1
CODIGO=$?
cat reportes/80_dast.txt

echo "$CODIGO" > reportes/.80_exit
[ "$CODIGO" -eq 0 ] && echo "  Resultado: PASA" || echo "  Resultado: FALLA (bloquea)"
exit "$CODIGO"
