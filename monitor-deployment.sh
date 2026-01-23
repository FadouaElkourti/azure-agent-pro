#!/bin/bash
RUN_ID=$1
REPO="FadouaElkourti/azure-agent-pro"

echo "📊 Monitoreando deployment Run ID: $RUN_ID"
echo "================================================"

for i in {1..30}; do
  echo ""
  echo "⏱️  Check #$i ($(date +%T))"
  
  STATUS=$(gh api repos/$REPO/actions/runs/$RUN_ID --jq '{status, conclusion}')
  echo "$STATUS"
  
  JOBS=$(gh run view $RUN_ID --repo $REPO 2>&1 | grep -E "^(✓|X|\*)" | head -5)
  echo "$JOBS"
  
  if echo "$STATUS" | grep -q '"status":"completed"'; then
    echo ""
    if echo "$STATUS" | grep -q '"conclusion":"success"'; then
      echo "🎉 ¡DEPLOYMENT EXITOSO!"
      gh run view $RUN_ID --repo $REPO
      exit 0
    else
      echo "❌ Deployment falló"
      gh run view $RUN_ID --repo $REPO --log-failed | grep -A 20 "ERROR:"
      exit 1
    fi
  fi
  
  sleep 30
done

echo "⏱️  Timeout después de 15 minutos"
