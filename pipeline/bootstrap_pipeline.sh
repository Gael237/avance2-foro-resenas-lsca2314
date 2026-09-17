#!/bin/bash
# Prepara las herramientas del pipeline de este proyecto.
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

mkdir -p bin reportes
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
  GL_ARCH="x64"; TR_ARCH="Linux-64bit"; SY_ARCH="amd64"
else
  GL_ARCH="arm64"; TR_ARCH="Linux-ARM64"; SY_ARCH="arm64"
fi

echo "[1/3] Descargando gitleaks y Trivy..."
if [ ! -f "bin/gitleaks" ]; then
  curl -sL -o /tmp/gl.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_${GL_ARCH}.tar.gz"
  tar xzf /tmp/gl.tar.gz -C bin gitleaks; chmod +x bin/gitleaks; rm -f /tmp/gl.tar.gz
fi
if [ ! -f "bin/trivy" ]; then
  curl -sL -o /tmp/tr.tar.gz "https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_${TR_ARCH}.tar.gz"
  tar xzf /tmp/tr.tar.gz -C bin trivy; chmod +x bin/trivy; rm -f /tmp/tr.tar.gz
fi
if [ ! -f "bin/syft" ]; then
  curl -sL -o /tmp/sy.tar.gz "https://github.com/anchore/syft/releases/download/v1.29.0/syft_1.29.0_linux_${SY_ARCH}.tar.gz"
  tar xzf /tmp/sy.tar.gz -C bin syft; chmod +x bin/syft; rm -f /tmp/sy.tar.gz
fi

echo "[2/3] Entorno virtual (semgrep, bandit, pip-audit, requests)..."
if [ ! -d "venv" ]; then python3 -m venv venv; fi
# shellcheck disable=SC1091
source venv/bin/activate
pip install --quiet --disable-pip-version-check --upgrade pip
pip install --quiet --disable-pip-version-check semgrep bandit "pip-audit<2.10" requests

echo "[3/3] Versiones:"
echo "  - gitleaks: $(./bin/gitleaks version)"
echo "  - trivy:    $(./bin/trivy --version | head -1)"
echo "  - syft:     $(SYFT_CHECK_FOR_APP_UPDATE=false ./bin/syft version 2>/dev/null | grep Version)"
echo "  - semgrep:  $(SEMGREP_SEND_METRICS=off semgrep --version --disable-version-check 2>/dev/null)"
echo "  - bandit:   $(bandit --version 2>&1 | head -1)"
echo "  - pip-audit: $(pip-audit --version)"
echo ""
echo "Entorno del pipeline listo."
