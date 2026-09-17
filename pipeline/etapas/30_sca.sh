#!/bin/bash
# Etapa 30 - Dependencias vulnerables (SCA).
# Se audita con Python 3.12 (dentro de un contenedor descartable), la MISMA
# version que corre en produccion via python:3.12-slim en los Dockerfiles.
# El host de esta instancia tiene Python 3.9, lo que resolveria versiones
# mas viejas de forma artificial y daria una falsa sensacion de que ciertas
# vulnerabilidades no tienen arreglo, cuando si lo tienen en el entorno real.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 30: dependencias (pip-audit con Python 3.12, igual que produccion) =="

docker run --rm -v "$DIR/app:/audit:ro" python:3.12-slim bash -c "
  pip install --quiet --disable-pip-version-check pip-audit
  echo '--- api/requirements.txt ---'
  pip-audit -r /audit/api/requirements.txt
  echo '__CODIGO_API__:'\$?
  echo '--- moderacion/requirements.txt ---'
  pip-audit -r /audit/moderacion/requirements.txt
  echo '__CODIGO_MOD__:'\$?
" > reportes/30_sca.txt 2>&1

COD_API=$(grep '__CODIGO_API__:' reportes/30_sca.txt | cut -d: -f2)
COD_MOD=$(grep '__CODIGO_MOD__:' reportes/30_sca.txt | cut -d: -f2)

cat reportes/30_sca.txt | grep -v "__CODIGO_"

if [ "$COD_API" = "0" ] && [ "$COD_MOD" = "0" ]; then
  echo "0" > reportes/.30_exit; echo "  Resultado: PASA"; exit 0
else
  echo "1" > reportes/.30_exit; echo "  Resultado: FALLA (bloquea)"; exit 1
fi
