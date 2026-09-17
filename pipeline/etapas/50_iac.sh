#!/bin/bash
# Etapa 50 - Infraestructura como codigo. Umbral: 0 HIGH/CRITICAL.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 50: infraestructura (trivy config sobre infra/) =="
./bin/trivy config infra > reportes/50_iac.txt 2>&1
./bin/trivy config infra --format json > reportes/50_iac.json 2>/dev/null

GRAVES=$(python3 -c "
import json
d=json.load(open('reportes/50_iac.json'))
n=0
for r in d.get('Results',[]):
    for m in r.get('Misconfigurations',[]):
        if m['Severity'] in ('HIGH','CRITICAL'): n+=1
print(n)
" 2>/dev/null || echo 99)

echo "  HIGH/CRITICAL: $GRAVES"
if [ "$GRAVES" -eq 0 ]; then
  echo "0" > reportes/.50_exit; echo "  Resultado: PASA"; exit 0
else
  echo "1" > reportes/.50_exit; echo "  Resultado: FALLA (bloquea)"; exit 1
fi
