#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="843976228713"
REPO_NAME="bia"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo "🚀 Deploy BIA - Tag: latest"

echo "📦 Autenticando no ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "🔨 Build da imagem..."
docker build -t ${ECR_URI}:latest .

echo "⬆️  Push para ECR..."
docker push ${ECR_URI}:latest

echo "✅ Deploy concluído!"
echo "📌 Imagem publicada: ${ECR_URI}:latest"
