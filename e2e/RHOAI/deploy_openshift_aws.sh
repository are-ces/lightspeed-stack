#!/usr/bin/env bash
set -euo pipefail

# Configurable variables
CLUSTER_NAME="e2elcs"
BASE_DOMAIN="ccxdev.devshift.net"
WORKDIR="./ocp-cluster"

# Prepare workdir
mkdir -p "$WORKDIR"
cat > "$WORKDIR/install-config.yaml" <<EOF
apiVersion: v1
baseDomain: ${BASE_DOMAIN}
metadata:
  name: ${CLUSTER_NAME}
platform:
  aws:
    region: ${AWS_DEFAULT_REGION}
pullSecret: '${PULL_SECRET}'
sshKey: '${SSH_KEY}'
EOF

echo "✅ install-config.yaml created in $WORKDIR"

# Run the installer
openshift-install create cluster --dir="$WORKDIR" --log-level=info
