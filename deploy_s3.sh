#!/usr/bin/env bash
set -euo pipefail

#############################################
# Caminho absoluto do projeto (onde está o script)
#############################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#############################################
# Configuração (defaults)
#############################################
S3_BUCKET="${S3_BUCKET:-fundamentosbiaweb}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CLIENT_DIR="${CLIENT_DIR:-${SCRIPT_DIR}/client}"

#############################################
# Checks
#############################################
command -v aws >/dev/null 2>&1 || { echo "ERRO: aws cli não encontrado"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "ERRO: npm não encontrado"; exit 1; }
test -d "${CLIENT_DIR}" || { echo "ERRO: diretório client não encontrado: ${CLIENT_DIR}"; exit 1; }

echo "==> Projeto: ${SCRIPT_DIR}"
echo "==> Client: ${CLIENT_DIR}"
echo "==> Bucket: s3://${S3_BUCKET}"
echo "==> Região: ${AWS_REGION}"

#############################################
# Build do Front (Vite)
#############################################
echo "==> Build do front (Vite)..."
cd "${CLIENT_DIR}"

rm -rf node_modules
npm install --legacy-peer-deps --loglevel=error

VITE_API_URL="${VITE_API_URL:-http://44.195.24.186}" npm run build

#############################################
# Detecta pasta de saída do Vite (build/ ou dist/)
#############################################
if [[ -d "${CLIENT_DIR}/dist" ]]; then
  DIST_DIR="${CLIENT_DIR}/dist"
elif [[ -d "${CLIENT_DIR}/build" ]]; then
  DIST_DIR="${CLIENT_DIR}/build"
else
  echo "ERRO: não encontrei ${CLIENT_DIR}/dist nem ${CLIENT_DIR}/build após o build."
  exit 1
fi

echo "==> Output do build: ${DIST_DIR}"
test -f "${DIST_DIR}/index.html" || { echo "ERRO: index.html não encontrado em ${DIST_DIR}"; exit 1; }

#############################################
# Deploy para S3
#############################################
echo "==> Upload assets com cache longo..."
aws s3 sync "${DIST_DIR}/" "s3://${S3_BUCKET}/" \
  --region "${AWS_REGION}" \
  --delete \
  --cache-control "public,max-age=31536000,immutable" \
  --exclude "index.html"

echo "==> Upload index.html sem cache..."
aws s3 cp "${DIST_DIR}/index.html" "s3://${S3_BUCKET}/index.html" \
  --region "${AWS_REGION}" \
  --cache-control "no-cache,no-store,must-revalidate" \
  --content-type "text/html; charset=utf-8"

echo "✅ Deploy concluído: s3://${S3_BUCKET}/"

