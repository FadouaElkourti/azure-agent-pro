#!/bin/bash
# Script para monitorear GitHub Actions deployment en tiempo real

set -euo pipefail

REPO="FadouaElkourti/azure-agent-pro"
WORKFLOW_NAME="Deploy Infrastructure"

echo "🔍 Monitoreando GitHub Actions deployment..."
echo "Repositorio: $REPO"
echo ""

# Loop para verificar estado cada 30 segundos
while true; do
  clear
  echo "═══════════════════════════════════════════════════════════"
  echo "📊 GitHub Actions Deployment Monitor"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  
  # Obtener último run
  LATEST_RUN=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status,conclusion,displayTitle,createdAt 2>/dev/null || echo "[]")
  
  if [ "$LATEST_RUN" != "[]" ]; then
    echo "$LATEST_RUN" | jq -r '.[] | "🏃 Run: \(.displayTitle)\n📅 Created: \(.createdAt)\n⚡ Status: \(.status)\n✅ Conclusion: \(.conclusion // "Running")\n"'
    
    RUN_ID=$(echo "$LATEST_RUN" | jq -r '.[0].databaseId')
    STATUS=$(echo "$LATEST_RUN" | jq -r '.[0].status')
    CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.[0].conclusion // "running"')
    
    # Mostrar jobs
    echo "───────────────────────────────────────────────────────────"
    echo "📦 Jobs:"
    gh run view "$RUN_ID" --repo "$REPO" 2>/dev/null | grep -E "^(✓|✗|-|○)" || echo "No jobs found"
    echo ""
    
    # Si completó, mostrar resultado final
    if [ "$STATUS" = "completed" ]; then
      echo "───────────────────────────────────────────────────────────"
      if [ "$CONCLUSION" = "success" ]; then
        echo "✅ DEPLOYMENT EXITOSO!"
        echo ""
        echo "Próximos pasos:"
        echo "1. Verificar recursos en Azure Portal"
        echo "2. Ejecutar smoke tests"
        echo "3. Validar conectividad"
        break
      elif [ "$CONCLUSION" = "failure" ]; then
        echo "❌ DEPLOYMENT FALLÓ"
        echo ""
        echo "Ver logs detallados:"
        echo "gh run view $RUN_ID --log --repo $REPO"
        break
      else
        echo "⚠️  Deployment terminó con estado: $CONCLUSION"
        break
      fi
    fi
  else
    echo "⏳ Esperando que se inicie un deployment..."
    echo ""
    echo "💡 Asegúrate de haber ejecutado el workflow desde:"
    echo "   https://github.com/$REPO/actions"
  fi
  
  echo ""
  echo "🔄 Actualizando en 30 segundos... (Ctrl+C para cancelar)"
  sleep 30
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Monitor finalizado: $(date)"
echo "═══════════════════════════════════════════════════════════"
