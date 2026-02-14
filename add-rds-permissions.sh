#!/bin/bash
set -e

ROLE_NAME="role-acesso-ssm"
POLICY_NAME="RDSAccessPolicy"

echo "🔐 Adicionando permissões RDS à role ${ROLE_NAME}..."

aws iam put-role-policy \
  --role-name ${ROLE_NAME} \
  --policy-name ${POLICY_NAME} \
  --policy-document file://rds-permissions.json

echo "✅ Permissões RDS adicionadas com sucesso!"
echo ""
echo "Permissões concedidas:"
echo "  - rds:DescribeDBInstances"
echo "  - rds:DescribeDBClusters"
echo "  - rds:StartDBInstance"
echo "  - rds:StopDBInstance"
echo "  - rds:RebootDBInstance"
