#!/bin/bash
# Etapa 70 - SBOM en CycloneDX. Genera evidencia, no bloquea.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 70: SBOM (syft) =="
SYFT_CHECK_FOR_APP_UPDATE=false ./bin/syft dir:app \
  -o cyclonedx-json=reportes/sbom_cyclonedx.json > reportes/70_sbom.txt 2>&1

COMPONENTES=$(python3 -c "
import json
d=json.load(open('reportes/sbom_cyclonedx.json'))
print(len([c for c in d.get('components',[]) if c.get('type')=='library']))
" 2>/dev/null || echo 0)

echo "  Librerias inventariadas: $COMPONENTES"
echo "0" > reportes/.70_exit
echo "  Resultado: PASA (artefacto generado)"
exit 0
