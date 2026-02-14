#!/bin/bash
set -euo pipefail

log(){ echo "==> $*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

need_mb(){ # need_mb <path> <min_mb>
  local path="$1" min="$2"
  local avail
  avail="$(df -Pm "$path" | awk 'NR==2{print $4}')"
  [[ "${avail:-0}" -ge "$min" ]]
}

# Workspace fixo no /home/ec2-user
WORKDIR="/home/ec2-user/setup-cache"
mkdir -p "$WORKDIR"
export TMPDIR="$WORKDIR/tmp"
mkdir -p "$TMPDIR"

log "Validando sistema (Amazon Linux 2023)..."
if ! grep -q 'Amazon Linux 2023' /etc/os-release; then
  echo "ERRO: Este script é para Amazon Linux 2023."
  cat /etc/os-release
  exit 1
fi

ARCH="$(uname -m)"

# =========================
# CORRIGIR PYTHON DO SISTEMA
# =========================
log "Checando python do sistema (dnf/yum dependem dele no AL2023)..."
PY39="/usr/bin/python3.9"
PYLINK="$(readlink -f /usr/bin/python3 2>/dev/null || true)"
if [[ "$PYLINK" != "$PY39" ]]; then
  if [[ -x "$PY39" ]]; then
    log "Ajustando /usr/bin/python3 -> $PY39"
    sudo ln -sf "$PY39" /usr/bin/python3
    sudo ln -sf "$PY39" /usr/bin/python
    hash -r
  else
    echo "ERRO: $PY39 não existe. Rode: ls -l /usr/bin/python3*"
    exit 1
  fi
fi
python3 -c "import dnf" >/dev/null 2>&1 || { echo "ERRO: dnf ainda quebrado."; exit 1; }

# =========================
# DEPENDÊNCIAS BÁSICAS
# =========================
log "Instalando dependências básicas..."
sudo dnf -y install unzip ca-certificates tar gzip git >/dev/null

# =========================
# DOCKER
# =========================
if have docker; then
  log "Docker já instalado. Pulando."
else
  log "Instalando Docker..."
  sudo dnf -y install docker
fi
sudo systemctl enable --now docker || true
sudo usermod -aG docker "$USER" || true

# =========================
# DOCKER COMPOSE v2 (plugin)
# =========================
if docker compose version >/dev/null 2>&1; then
  log "Docker Compose v2 já disponível. Pulando."
else
  log "Instalando Docker Compose v2 (plugin)..."
  if [[ "$ARCH" == "x86_64" ]]; then
    COMPOSE_BIN="docker-compose-linux-x86_64"
  elif [[ "$ARCH" == "aarch64" ]]; then
    COMPOSE_BIN="docker-compose-linux-aarch64"
  else
    echo "ERRO: arquitetura não suportada para docker compose: $ARCH"
    exit 1
  fi
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -sS -L "https://github.com/docker/compose/releases/latest/download/${COMPOSE_BIN}" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

# =========================
# NODE 20 LTS (NVM) - usando TMPDIR no /home/ec2-user
# =========================
need_node20="yes"
if have node; then
  NODE_MAJ="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo "")"
  [[ "$NODE_MAJ" == "20" ]] && need_node20="no"
fi

if [[ "$need_node20" == "no" ]]; then
  log "Node.js 20 já instalado. Pulando."
else
  log "Checando espaço em ${WORKDIR} para instalar Node..."
  if ! need_mb "$WORKDIR" 500; then
    echo "ERRO: pouco espaço em $WORKDIR para instalar Node via NVM."
    echo "Rode: df -h $WORKDIR"
    exit 1
  fi

  log "Instalando Node.js 20 LTS via NVM..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -sS -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
  nvm install 20
  nvm alias default 20
  nvm use default

  if ! grep -q 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc; then
    cat >> ~/.bashrc <<'EOF'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
  fi
fi

# =========================
# AWS CLI v2 - baixar/extraír no WORKDIR (sem /tmp)
# =========================
if have aws; then
  log "AWS CLI já instalado. Pulando."
else
  log "Instalando AWS CLI v2..."
  if ! need_mb "$WORKDIR" 300; then
    echo "ERRO: pouco espaço em $WORKDIR para AWS CLI."
    exit 1
  fi

  AWSCLI_ZIP="$WORKDIR/awscliv2.zip"
  AWSCLI_DIR="$WORKDIR/aws"
  rm -rf "$AWSCLI_DIR"

  if [[ "$ARCH" == "x86_64" ]]; then
    AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  elif [[ "$ARCH" == "aarch64" ]]; then
    AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  else
    echo "ERRO: arquitetura não suportada para AWS CLI: $ARCH"
    exit 1
  fi

  curl -sS "$AWSCLI_URL" -o "$AWSCLI_ZIP"
  unzip -qo "$AWSCLI_ZIP" -d "$WORKDIR"
  sudo "$AWSCLI_DIR/install" --update
fi

# =========================
# AMAZON Q CLI (ZIP) - baixar/instalar no WORKDIR (sem /tmp)
# =========================
if have q; then
  log "Amazon Q CLI já instalado. Pulando."
else
  log "Instalando Amazon Q CLI via ZIP..."
  if ! need_mb "$WORKDIR" 250; then
    echo "ERRO: pouco espaço em $WORKDIR para Amazon Q."
    exit 1
  fi

  Q_ZIP="$WORKDIR/q.zip"
  Q_DIR="$WORKDIR/q"
  rm -rf "$Q_DIR"

  if [[ "$ARCH" == "x86_64" ]]; then
    Q_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip"
  elif [[ "$ARCH" == "aarch64" ]]; then
    Q_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/q-aarch64-linux.zip"
  else
    echo "ERRO: arquitetura não suportada para Amazon Q: $ARCH"
    exit 1
  fi

  curl --proto '=https' --tlsv1.2 -sSfL "$Q_URL" -o "$Q_ZIP"
  test -s "$Q_ZIP" || { echo "ERRO: download do Amazon Q vazio."; exit 1; }

  unzip -q "$Q_ZIP" -d "$WORKDIR"
  chmod +x "$Q_DIR/install.sh"
  "$Q_DIR/install.sh"

  # PATH para ~/.local/bin (onde o q costuma ficar)
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

# =========================
# RESUMO
# =========================
log "Validando versões..."
docker --version || true
docker compose version || true
node -v || true
npm -v || true
aws --version || true
q --version || true

echo "========================================="
echo "✅ Setup concluído (idempotente)."
echo "➡️ Se docker ainda pedir sudo, faça logout/login (grupo docker)."
echo "➡️ Para autenticar no Amazon Q: q login"
echo "========================================="

