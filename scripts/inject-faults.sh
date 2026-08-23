#!/bin/bash
# inject-faults.sh — Break the payment-service to trigger SwarmSRE detection
set -e

echo "═══════════════════════════════════════════════"
echo "  💥 SwarmSRE Chaos Injection"
echo "═══════════════════════════════════════════════"

# Pre-flight: verify cluster is healthy
echo "🔍 Pre-flight check..."
if ! kubectl get deployment payment-service -n demo &>/dev/null; then
    echo "❌ ERROR: payment-service not found in demo namespace."
    echo "   Run './scripts/deploy-apps.sh' first."
    exit 1
fi

CURRENT_IMAGE=$(kubectl get deployment payment-service -n demo -o jsonpath='{.spec.template.spec.containers[0].image}')
if [ "$CURRENT_IMAGE" = "nginx:broken-tag" ]; then
    echo "⚠️  payment-service is already broken (image: nginx:broken-tag)."
    echo "   Run './scripts/reset-demo.sh' first to restore it."
    exit 1
fi

echo "✅ Cluster is healthy. Current image: ${CURRENT_IMAGE}"
echo ""

# Inject chaos
echo "🚀 Injecting Chaos: Breaking the Payment Service..."
kubectl patch deployment payment-service -n demo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"nginx:broken-tag"}]'

echo ""
echo "⏳ Waiting for CrashLoopBackOff event..."
kubectl wait --for=condition=Available=False deployment/payment-service -n demo --timeout=30s || true

echo ""
echo "═══════════════════════════════════════════════"
echo "  💥 Chaos Injected Successfully!"
echo "  The SwarmSRE agent should detect this within"
echo "  ~10 seconds and begin Root Cause Analysis."
echo "═══════════════════════════════════════════════"
