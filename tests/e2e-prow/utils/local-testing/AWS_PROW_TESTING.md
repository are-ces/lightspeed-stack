# Running Prow E2E Tests Locally on AWS

## Overview
When testing changes to Prow tests, best practice is to validate them outside of Prow using an AWS account. Prow tests take ~1 hour to run and are ephemeral, making iteration slow. AWS offers persistent infrastructure: while the initial OpenShift cluster setup still takes ~1 hour, you only do this once (once per work session). The cluster persists between test runs, allowing rapid iteration without destroying and recreating resources.

> [!WARNING]
> Remember to destroy the OpenShift cluster when done or at the end of the day with `openshift-install destroy cluster --dir="$OPENSHIFT_WORKDIR"`, as keeping the cluster running will incur costs. Keep in mind that autopruning is enabled so your cluster will eventually be automatically pruned.


## Prerequisites

### Required Environment Variables

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-2"  # or your preferred region

# SSH access
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"  # or path to your public key

# OpenShift pull secret (get from https://console.redhat.com/openshift/install/pull-secret)
export PULL_SECRET='{"auths":...}'

# Local working directory for AWS files
export OPENSHIFT_WORKDIR="./ocp-cluster"

# HuggingFace token (optional, only needed for model inference)
export HUGGING_FACE_HUB_TOKEN="your-token"

# Cluster configuration
export CLUSTER_NAME="your-rh-username"  # Include a name which can be traced to your RH username (e.g., qtarantinotesting)
export BASE_DOMAIN="your-aws-account-domain"
```

## Setup Steps

### 1. Install Prerequisites
```bash
./scripts/openshift-installer-install.sh
./scripts/oc-install.sh
```

### 2. Create OpenShift Cluster
```bash
./scripts/aws-openshift-install.sh
```
**Wait ~1 hour for cluster provisioning to complete.**
Congratulations! Your openshift cluster is up and running.

Set the kubeconfig to interact with your cluster:
```bash
export KUBECONFIG=$OPENSHIFT_WORKDIR/auth/kubeconfig
```

### 3. Run Tests

Edit `pipeline.sh` to comment out Prow-specific secret mounts:
```bash
# Comment out lines like:
# export HUGGING_FACE_HUB_TOKEN=$(cat /var/run/huggingface/hf-token-ces-lcore-test || true)
```

Then run:
```bash
cd ../../rhoai
./pipeline.sh
```

### 4. Clean Up OpenShift Cluster

To bring the OpenShift cluster back to a clean state between test runs, delete all pods and definitions:
```bash
./scripts/delete-all-resources.sh
```

