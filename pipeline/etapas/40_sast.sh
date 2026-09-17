#!/bin/bash
# Etapa 40 - Analisis estatico del codigo propio (SAST).
# Umbral: 0 ERROR en semgrep (reglas p/security-audit) y 0 HIGH en bandit.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes
# shellcheck disable=SC1091
source venv/bin/activate
export SEMGREP_SEND_METRICS=off

echo "== Etapa 40: SAST (semgrep + bandit) sobre app/ =="

semgrep --config p/security-audit app --disable-version-check \
  --json > reportes/40_semgrep.json 2>/dev/null
semgrep --config p/security-audit app --disable-version-check \
  --quiet > reportes/40_semgrep.txt 2>&1

bandit -r app -f json > reportes/40_bandit.json 2>/dev/null
bandit -r app -f txt > reportes/40_bandit.txt 2>&1

ERRORES=$(python3 -c "
import json
d=json.load(open('reportes/40_semgrep.json'))
print(len([r for r in d.get('results',[]) if r['extra']['severity']=='ERROR']))
" 2>/dev/null || echo 99)

ALTOS=$(python3 -c "
import json
d=json.load(open('reportes/40_bandit.json'))
print(len([r for r in d.get('results',[]) if r['issue_severity']=='HIGH']))
" 2>/dev/null || echo 99)

echo "  semgrep ERROR: $ERRORES  |  bandit HIGH: $ALTOS"
if [ "$ERRORES" -eq 0 ] && [ "$ALTOS" -eq 0 ]; then
  echo "0" > reportes/.40_exit; echo "  Resultado: PASA"; exit 0
else
  echo "1" > reportes/.40_exit; echo "  Resultado: FALLA (bloquea)"; exit 1
fi
