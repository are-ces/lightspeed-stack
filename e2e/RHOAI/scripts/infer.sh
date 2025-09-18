#!/bin/bash

source pod.env         

API_KEY="$1"

echo "WAITING FOR POD TO FINISH"

oc get pods

sleep 200

oc get pods

curl --cacert router-ca.crt \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_KEY" \
     -d '{
        "model": "meta-llama/Llama-3.2-1B-Instruct",
        "prompt": "You are a helpful assistant. Who won the world series in 2020?",
        "max_new_tokens": 100
     }' \
     "$KSVC_URL/v1/completions"
