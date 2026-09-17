#!/bin/bash
# Etapa 60 - Dockerfiles de los 2 servicios. Umbral: 0 HIGH/CRITICAL cada uno.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 60: imagenes de contenedor (trivy config) =="
./bin/trivy config app/api/Dockerfile --format json > reportes/60_api.json 2>/dev/null
./bin/trivy config app/api/Dockerfile > reportes/60_api.txt 2>&1
./bin/trivy config app/moderacion/Dockerfile --format json > reportes/60_moderacion.json 2>/dev/null
./bin/trivy config app/moderacion/Dockerfile > reportes/60_moderacion.txt 2>&1

contar_graves() {
  python3 -c "
import json
d=json.load(open('$1'))
n=0
for r in d.get('Results',[]):
    for m in r.get('Misconfigurations',[]):
        if m['Severity'] in ('HIGH','CRITICAL'): n+=1
print(n)
" 2>/dev/null || echo 99
}
G1=$(contar_graves reportes/60_api.json)
G2=$(contar_graves reportes/60_moderacion.json)
echo "  api: $G1 HIGH/CRITICAL  |  moderacion: $G2 HIGH/CRITICAL"

if [ "$G1" -eq 0 ] && [ "$G2" -eq 0 ]; then
  echo "0" > reportes/.60_exit; echo "  Resultado: PASA"; exit 0
else
  echo "1" > reportes/.60_exit; echo "  Resultado: FALLA (bloquea)"; exit 1
fi
