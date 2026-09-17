#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR" || exit 1

echo "=================================================="
echo " Pipeline - Foro y Resenas de Productos"
echo "=================================================="
echo ""

bash pipeline/etapas/10_secretos.sh; echo ""
bash pipeline/etapas/20_secretos_historial.sh; echo ""
bash pipeline/etapas/30_sca.sh; echo ""
bash pipeline/etapas/40_sast.sh; echo ""
bash pipeline/etapas/50_iac.sh; echo ""
bash pipeline/etapas/60_imagen.sh; echo ""
bash pipeline/etapas/70_sbom.sh; echo ""
bash pipeline/etapas/80_dast.sh; echo ""

docker compose down > /dev/null 2>&1

bash pipeline/etapas/90_gate.sh
exit $?
