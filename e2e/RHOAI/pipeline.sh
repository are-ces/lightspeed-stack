#!/bin/bash

PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$PIPELINE_DIR/scripts/bootstrap.sh" "$PIPELINE_DIR"
"$PIPELINE_DIR/scripts/deploy-pod.sh" "$PIPELINE_DIR"
"$PIPELINE_DIR/scripts/fetch-ca.sh" 
"$PIPELINE_DIR/scripts/get-pod-info.sh" 