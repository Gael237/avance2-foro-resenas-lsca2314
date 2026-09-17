#!/bin/bash
# Etapa 10 - Secretos en el codigo actual del repositorio.
# Alcance: solo el codigo de la aplicacion y del pipeline, NO infra/ (que
# contiene el estado de Terraform, protegido por .gitignore pero que por
# naturaleza guarda credenciales en texto plano en disco -- limitacion
# conocida de Terraform sin backend remoto cifrado, fuera del alcance de
# este control).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DIR" || exit 1
mkdir -p reportes

echo "== Etapa 10: secretos en el codigo (app/, pipeline/, docs/, raiz) =="
> reportes/10_secretos.txt
CODIGO_TOTAL=0

for carpeta in app pipeline docs; do
  ./bin/gitleaks dir "$carpeta" --no-color -v >> reportes/10_secretos.txt 2>&1
  [ $? -ne 0 ] && CODIGO_TOTAL=1
done

for archivo in docker-compose.yml .gitignore README.md; do
  if [ -f "$archivo" ]; then
    ./bin/gitleaks dir "$archivo" --no-color -v >> reportes/10_secretos.txt 2>&1
    [ $? -ne 0 ] && CODIGO_TOTAL=1
  fi
done

echo "$CODIGO_TOTAL" > reportes/.10_exit
[ "$CODIGO_TOTAL" -eq 0 ] && echo "  Resultado: PASA" || echo "  Resultado: FALLA (bloquea)"
exit "$CODIGO_TOTAL"
