#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit 1

TOTAL=0; OK=0
check() {
  TOTAL=$((TOTAL+1))
  if eval "$2"; then echo "  [OK] $1"; OK=$((OK+1)); else echo "  [ ] $1"; fi
}

echo "=================================================="
echo " Verificacion de entrega - Avance 2"
echo "=================================================="

check "app/ existe" "[ -d app ]"
check "docker-compose.yml existe" "[ -f docker-compose.yml ]"
check "Dockerfiles existen (api y moderacion)" "[ -f app/api/Dockerfile ] && [ -f app/moderacion/Dockerfile ]"
check "infra/*.tf existe" "ls infra/*.tf >/dev/null 2>&1"
check "pipeline/ existe" "[ -d pipeline ]"
check "reportes/corrida_roja.txt existe y contiene BLOQUEADO" "grep -q BLOQUEADO reportes/corrida_roja.txt 2>/dev/null"
check "reportes/corrida_verde.txt existe y contiene PERMITIDO" "grep -q PERMITIDO reportes/corrida_verde.txt 2>/dev/null"
check "reportes/sbom_cyclonedx.json existe" "[ -f reportes/sbom_cyclonedx.json ]"
check "docs/README.md existe" "[ -f docs/README.md ]"
check "docs/diagrama_arquitectura.png existe" "[ -f docs/diagrama_arquitectura.png ]"
check "docs/ADR-001-decisiones-tecnicas.md existe" "[ -f docs/ADR-001-decisiones-tecnicas.md ]"
check "docs/tabla_decisiones_pipeline.md existe" "[ -f docs/tabla_decisiones_pipeline.md ]"
check "docs/declaracion_uso_ia.md existe" "[ -f docs/declaracion_uso_ia.md ]"
check "video/ o docs/enlace_video.txt existe" "[ -d video ] && [ \"\$(ls -A video 2>/dev/null)\" ] || [ -f docs/enlace_video.txt ]"
check "Sin placeholders [COMPLETAR] pendientes en docs/" "! grep -rq '\[COMPLETAR\]\|\[.*AQUI.*\]' docs/ 2>/dev/null"
check ".env NO esta en el repositorio (verificado con git)" "! git ls-files | grep -q '^\.env$'"
check "terraform.tfvars y .tfstate NO estan en el repositorio" "! git ls-files | grep -qE 'tfvars$|tfstate'"

echo ""
echo "=================================================="
echo " Resultado: $OK / $TOTAL"
echo "=================================================="
[ "$OK" -eq "$TOTAL" ] && echo "Entrega completa." || echo "Faltan piezas, revisa la lista de arriba."
