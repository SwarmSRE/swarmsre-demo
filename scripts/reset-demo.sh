#!/bin/bash
# reset-demo.sh — Restore all demo services to healthy state
set -e

echo "═══════════════════════════════════════════════"
echo "  🧹 SwarmSRE Demo Reset"
echo "═══════════════════════════════════════════════"

# Restore payment-service image
echo "🔧 Restoring payment-service..."
kubectl patch deployment payment-service -n demo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"nginx:alpine"}]' 2>/dev/null || true

# Restore backend-service image (in case it was also broken)
echo "🔧 Restoring backend-service..."
kubectl patch deployment backend-service -n demo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"nginx:alpine"}]' 2>/dev/null || true

# Restore api-gateway image
echo "🔧 Restoring api-gateway..."
kubectl patch deployment api-gateway -n demo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"nginx:alpine"}]' 2>/dev/null || true

# Clean up any Chaos Mesh objects
kubectl delete networkchaos --all -n demo 2>/dev/null || true
kubectl delete podchaos --all -n demo 2>/dev/null || true

echo ""
echo "⏳ Waiting for all services to recover..."
kubectl wait --for=condition=Available=True deployment/api-gateway -n demo --timeout=60s
kubectl wait --for=condition=Available=True deployment/backend-service -n demo --timeout=60s
kubectl wait --for=condition=Available=True deployment/payment-service -n demo --timeout=60s

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Environment Reset Successfully!"
echo "═══════════════════════════════════════════════"
kubectl get pods -n demo
