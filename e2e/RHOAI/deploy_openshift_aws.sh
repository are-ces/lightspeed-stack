#!/usr/bin/env bash
set -euo pipefail

# Configurable variables
TODAY=$(date '+%d%m%Y')

CLUSTER_NAME="${CLUSTER_NAME}.${TODAY}"

# Prepare workdir
mkdir -p "$OPENSHIFT_WORKDIR"
cat > "$OPENSHIFT_WORKDIR/install-config.yaml" <<EOF
apiVersion: v1
baseDomain: ${BASE_DOMAIN}
metadata:
  name: ${CLUSTER_NAME}
platform:
  aws:
    region: ${AWS_DEFAULT_REGION}
pullSecret: '${PULL_SECRET}'
sshKey: '${SSH_PUBLIC_KEY}'
EOF

echo "✅ install-config.yaml created in $OPENSHIFT_WORKDIR"

# Run the installer
openshift-install create cluster --dir="$OPENSHIFT_WORKDIR" --log-level=debug
