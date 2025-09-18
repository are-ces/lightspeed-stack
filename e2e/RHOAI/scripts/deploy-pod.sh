#!/bin/bash

BASE_DIR="$1"

# Wait for ServingRuntime CRD
oc wait --for=condition=established crd/servingruntimes.serving.kserve.io --timeout=120s

# Wait for InferenceService CRD
oc wait --for=condition=established crd/inferenceservices.serving.kserve.io --timeout=120s

oc apply -f "$BASE_DIR/config/pod/vllm-runtime-cpu.yaml"

# # Wait for the CRD to be recognized by the API server
# CRD_NAME="vllmruntimes.serving.kserve.io"

# # Only wait if it exists
# if oc get crd "$CRD_NAME" >/dev/null 2>&1; then
#     echo "Waiting for CRD $CRD_NAME to be deleted..."
#     until ! oc get crd "$CRD_NAME" >/dev/null 2>&1; do
#         sleep 2
#     done
#fi

oc apply -f "$BASE_DIR/config/pod/inference-service.yaml"