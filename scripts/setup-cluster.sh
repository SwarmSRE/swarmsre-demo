#!/bin/bash
# setup-cluster.sh — Idempotent KinD cluster provisioning for SwarmSRE
set -e

CLUSTER_NAME="swarmsre-demo"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "═══════════════════════════════════════════════"
echo "  SwarmSRE Demo Cluster Setup"
echo "═══════════════════════════════════════════════"

# --- Step 1: Create or reuse KinD cluster ---
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "✅ Cluster '${CLUSTER_NAME}' already exists."

    # Ensure the Docker container is running
    if ! docker inspect -f '{{.State.Running}}' "${CLUSTER_NAME}-control-plane" 2>/dev/null | grep -q "true"; then
        echo "⚠️  Cluster container is stopped. Restarting..."
        docker start "${CLUSTER_NAME}-control-plane"
        sleep 3
    fi
else
    echo "🚀 Creating KinD cluster: ${CLUSTER_NAME}..."
    kind create cluster --name "${CLUSTER_NAME}" --config "${DIR}/kind-config.yaml"
fi

# --- Step 2: Verify API connectivity ---
echo ""
echo "🔍 Verifying Kubernetes API connectivity..."
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ ERROR: Cannot reach the Kubernetes API. Check Docker and KinD status."
    exit 1
fi
echo "✅ Kubernetes API is reachable."

# --- Step 3: Install NGINX Ingress Controller ---
echo ""
echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml 2>/dev/null || true

echo "⏳ Waiting for NGINX Ingress to be ready..."
sleep 10
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s 2>/dev/null || echo "⚠️  Ingress controller not ready yet (non-blocking)."

# --- Step 4: Create namespaces ---
echo ""
echo "📁 Creating namespaces..."
kubectl create namespace swarmsre-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

# --- Step 5: Health check ---
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Cluster Setup Complete!"
echo "═══════════════════════════════════════════════"
kubectl get nodes
echo ""
echo "Next: Run './scripts/deploy-apps.sh' to deploy demo services."
