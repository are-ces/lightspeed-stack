#!/bin/bash

source pod.env         

API_KEY="$1"

echo "WAITING FOR POD TO FINISH"

oc get pods

sleep 200

oc get pods

####
echo "⏳ Waiting for service at $KSVC_URL/v1/models (timeout 1000s)..."

START=$(date +%s)
TIMEOUT=200

while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  --cacert router-ca.crt \
  "$KSVC_URL/v1/models")

  if [ "$STATUS" -eq 200 ]; then
    echo "✅ Service is ready at $KSVC_URL/v1/models"
    break
  fi

  NOW=$(date +%s)
  ELAPSED=$((NOW - START))

  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "❌ Timeout reached ($TIMEOUT seconds). Service did not become ready."
    break
  fi

  echo "⏳ Still waiting... ($ELAPSED/$TIMEOUT seconds elapsed)"
  sleep 10
done

oc describe pod $(oc get pods -o jsonpath='{.items[0].metadata.name}')

####

echo "Calling $KSVC_URL/v1/completions"

curl --cacert router-ca.crt \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_KEY" \
     -d '{
        "model": "meta-llama/Llama-3.2-1B-Instruct",
        "prompt": "You are a helpful assistant. Who won the world series in 2020?",
        "max_new_tokens": 100
     }' \
     "$KSVC_URL/v1/completions"
