#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="843976228713"
REPO_NAME="bia"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"
CLUSTER="cluster-t3-alb"
SERVICE="service-t3-alb"

VERSION=$(date +%Y%m%d-%H%M%S)

echo "🤖 Deploy BIA com IA - Versão: ${VERSION}"
echo ""

echo "🔍 Identificando ALB..."
ALB_DNS=$(aws elbv2 describe-load-balancers --region ${REGION} --query 'LoadBalancers[0].DNSName' --output text)
echo "✅ ALB encontrado: ${ALB_DNS}"
echo ""

echo "📝 Atualizando Dockerfile com URL do ALB..."
sed -i "s|VITE_API_URL=http://[^ ]*|VITE_API_URL=http://${ALB_DNS}|g" Dockerfile
echo "✅ Dockerfile atualizado"
echo ""

echo "📦 Autenticando no ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URI}
echo ""

echo "🔨 Build da imagem..."
docker build -t ${REPO_NAME}:${VERSION} .
echo ""

echo "🏷️  Tagueando imagens..."
docker tag ${REPO_NAME}:${VERSION} ${ECR_URI}:${VERSION}
docker tag ${REPO_NAME}:${VERSION} ${ECR_URI}:latest
echo ""

echo "⬆️  Push para ECR..."
docker push ${ECR_URI}:${VERSION}
docker push ${ECR_URI}:latest
echo ""

echo "🚀 Atualizando serviço ECS..."
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --force-new-deployment --region ${REGION} > /dev/null
echo "✅ Deployment iniciado"
echo ""

echo "⏳ Monitorando deployment..."
for i in {1..10}; do
  STATUS=$(aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE} --region ${REGION} --query 'services[0].{Running:runningCount,Pending:pendingCount}' --output json)
  RUNNING=$(echo $STATUS | jq -r '.Running')
  PENDING=$(echo $STATUS | jq -r '.Pending')
  
  echo "[$i/10] Running: ${RUNNING}, Pending: ${PENDING}"
  
  if [ "$RUNNING" = "2" ] && [ "$PENDING" = "0" ]; then
    echo ""
    echo "✅ Deployment concluído!"
    break
  fi
  
  if [ $i -lt 10 ]; then
    sleep 60
  fi
done
echo ""

echo "🧪 Testando aplicação..."
RESPONSE=$(curl -s http://${ALB_DNS}/api/versao)
echo "Resposta: ${RESPONSE}"
echo ""

echo "✅ Deploy completo!"
echo "📌 Versão: ${VERSION}"
echo "🌐 URL: http://${ALB_DNS}"
