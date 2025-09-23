#!/bin/bash

BASE_DIR="$1"

# Wait until the CRDs exist
for crd in servingruntimes.serving.kserve.io inferenceservices.serving.kserve.io; do
  echo "Waiting for CRD $crd to exist..."
  until oc get crd $crd &>/dev/null; do
    sleep 5
  done
  echo "CRD $crd exists. Waiting to be established..."
  oc wait --for=condition=established crd/$crd --timeout=120s
done

oc rollout status deployment/kserve-controller-manager -n redhat-ods-applications --timeout=180s

sleep 20

oc apply -f "$BASE_DIR/config/pod/vllm-runtime-cpu.yaml"

oc apply -f "$BASE_DIR/config/pod/inference-service.yaml"