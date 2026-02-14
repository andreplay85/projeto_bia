#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="843976228713"
REPO_NAME="bia"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

VERSION=$(date +%Y%m%d-%H%M%S)

echo "🚀 Deploy BIA - Versão: ${VERSION}"

echo "📦 Autenticando no ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URI}

echo "🔨 Build da imagem..."
docker build -t ${REPO_NAME}:${VERSION} .

echo "🏷️  Tagueando imagens..."
docker tag ${REPO_NAME}:${VERSION} ${ECR_URI}:${VERSION}
docker tag ${REPO_NAME}:${VERSION} ${ECR_URI}:latest

echo "⬆️  Push para ECR..."
docker push ${ECR_URI}:${VERSION}
docker push ${ECR_URI}:latest

echo "✅ Deploy concluído!"
echo "📌 Imagem: ${ECR_URI}:${VERSION}"
