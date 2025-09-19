#!/bin/bash
set -e

# --- CONFIGURATION ---
NAMESPACE="${NAMESPACE:-default}"
ISVC_NAME="${1:-vllm-model}"
ENV_FILE="${ENV_FILE:-pod.env}"

# Derive the Knative Service name
KSVC_NAME="${ISVC_NAME}-predictor"

echo "--> Finding the pod for InferenceService '$ISVC_NAME'..."

# 1. Find the running pod for the InferenceService
POD_NAME=""
until [ -n "$POD_NAME" ]; do
  POD_NAME=$(oc get pods -n "$NAMESPACE" \
    -l "serving.kserve.io/inferenceservice=$ISVC_NAME" \
    -o jsonpath="{.items[?(@.status.phase=='Running')].metadata.name}" 2>/dev/null)
  if [ -z "$POD_NAME" ]; then
    echo "  -> Pod not running yet, waiting 5 seconds..."
    sleep 5
  fi
done
echo "  -> Found running pod: $POD_NAME"

# 2. Get the 'app' label for Service selector
APP_LABEL=$(oc get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.labels.app}')
if [ -z "$APP_LABEL" ]; then
  echo "Error: Could not find 'app' label on pod $POD_NAME"
  exit 1
fi
echo "  -> Found 'app' label: $APP_LABEL"

# 3. Get the Knative Service URL
KSVC_URL=$(oc get ksvc "$KSVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.url}')
if [ -z "$KSVC_URL" ]; then
  echo "Error: Could not retrieve Knative URL for $KSVC_NAME"
  exit 1
fi
echo "  -> Found Knative URL: $KSVC_URL"

# 4. Save all info to pod.env
cat <<EOF > "$ENV_FILE"
# Environment variables for the vLLM service
POD_NAME=$POD_NAME
APP_LABEL=$APP_LABEL
NAMESPACE=$NAMESPACE
ISVC_NAME=$ISVC_NAME
KSVC_NAME=$KSVC_NAME
KSVC_URL=$KSVC_URL
EOF

echo "✅ Success! Details saved in $ENV_FILE."
