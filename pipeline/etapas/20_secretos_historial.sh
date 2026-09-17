#!/bin/bash
# Etapa 20 - Secretos en TODO el historial de commits de este repo.
# No bloquea: un secreto ya publicado exige rotacion, no puede "des-publicarse".
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 20: secretos en el HISTORIAL completo (gitleaks git) =="
./bin/gitleaks git . --no-color -v > reportes/20_historial.txt 2>&1
CODIGO=$?
HALLAZGOS=$(grep -c "RuleID:" reportes/20_historial.txt 2>/dev/null || echo 0)
echo "  Hallazgos en el historial: $HALLAZGOS"
echo "0" > reportes/.20_exit
exit 0
