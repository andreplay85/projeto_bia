set -e

# 1) Backup do diretório do Q (se existir)
if [ -d ~/.aws/amazonq ]; then
  mv ~/.aws/amazonq ~/.aws/amazonq.bkp.$(date +%F_%H%M%S)
  echo "Backup feito: ~/.aws/amazonq.bkp.*"
else
  echo "Diretório ~/.aws/amazonq não existe."
fi

# 2) (opcional) backup de cache (algumas versões usam)
if [ -d ~/.cache/amazonq ]; then
  mv ~/.cache/amazonq ~/.cache/amazonq.bkp.$(date +%F_%H%M%S)
  echo "Backup feito: ~/.cache/amazonq.bkp.*"
fi

# Backup do diretório de agents
mv ~/.aws/amazonq/cli-agents ~/.aws/amazonq/cli-agents.disabled

