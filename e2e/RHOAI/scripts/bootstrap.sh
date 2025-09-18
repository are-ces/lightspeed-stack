#!/bin/bash
# Apply Kubernetes resources sequentially, waiting for
# operators to become ready before proceeding.

set -euo pipefail

BASE_DIR="$1"

wait_for_operator() {
  local OPERATOR_LABEL=$1
  local NAMESPACE=$2
  local OPERATOR_NAME=$3

  echo "  -> Waiting for ${OPERATOR_NAME} CSV resource to be created in namespace ${NAMESPACE}..."
  until oc get csv -n "${NAMESPACE}" -l "${OPERATOR_LABEL}" --no-headers 2>/dev/null | grep -q .; do
    echo "     ...still waiting for ${OPERATOR_NAME} CSV to show up"
    sleep 5
  done

  echo "  -> Waiting for ${OPERATOR_NAME} CSV to reach Succeeded..."
  oc wait --for=jsonpath='{.status.phase}'=Succeeded csv -n "${NAMESPACE}" -l "${OPERATOR_LABEL}" --timeout=600s
}

# --- STAGE 1: APPLY OPERATOR SUBSCRIPTIONS ---
echo "--> Applying Operator Subscriptions from operators.yaml..."
oc apply -f "$BASE_DIR/config/operators/operators.yaml"

# --- STAGE 2: WAIT FOR OPERATORS TO BECOME READY ---
echo "--> Waiting for Operators to be installed. This can take several minutes..."

# Ensure the ClusterServiceVersion CRD exists before checking for CSVs
oc wait --for=condition=established --timeout=300s crd/clusterserviceversions.operators.coreos.com

# Wait for each operator
wait_for_operator "operators.coreos.com/servicemeshoperator.openshift-operators" "openshift-operators" "Service Mesh Operator"
wait_for_operator "operators.coreos.com/serverless-operator.openshift-operators" "openshift-operators" "Serverless Operator"
wait_for_operator "operators.coreos.com/rhods-operator.openshift-operators" "openshift-operators" "RHODS Operator"

echo "--> All operators are ready."

# --- STAGE 3: APPLY DEPENDENT RESOURCES ---
echo "--> Applying OperatorGroup from operatorgroup.yaml..."
oc apply -f "$BASE_DIR/config/operators/operatorgroup.yaml"

echo "--> Applying DataScienceCluster from ds-cluster.yaml..."
oc apply -f "$BASE_DIR/config/operators/ds-cluster.yaml"

echo "All files applied successfully. The DataScienceCluster is now provisioning."
