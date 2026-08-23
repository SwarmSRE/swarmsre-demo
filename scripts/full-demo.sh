#!/bin/bash
# full-demo.sh — One-click orchestrator for the 90-second live presentation
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_PLANE_DIR="${DIR}/../../swarmsre-control-plane"

echo "═══════════════════════════════════════════════"
echo "  🎬 SwarmSRE Full Demo Orchestrator"
echo "  DevOpsDays Cairo 2026"
echo "═══════════════════════════════════════════════"
echo ""

# --- Step 1: Verify cluster health ---
echo "📋 Step 1/4: Verifying cluster health..."
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ KinD cluster is not reachable. Starting it..."
    bash "${DIR}/setup-cluster.sh"
fi

# Check demo apps
if ! kubectl get deployment payment-service -n demo &>/dev/null; then
    echo "⚠️  Demo apps not deployed. Deploying now..."
    bash "${DIR}/deploy-apps.sh"
else
    # Reset to clean state if needed
    CURRENT_IMAGE=$(kubectl get deployment payment-service -n demo -o jsonpath='{.spec.template.spec.containers[0].image}')
    if [ "$CURRENT_IMAGE" != "nginx:alpine" ]; then
        echo "⚠️  Demo environment is dirty. Resetting..."
        bash "${DIR}/reset-demo.sh"
    else
        echo "✅ Cluster and demo apps are healthy."
    fi
fi

# --- Step 2: Start PostgreSQL ---
echo ""
echo "📋 Step 2/4: Ensuring PostgreSQL is running..."
docker start swarmsre-pg 2>/dev/null || true
sleep 1

# --- Step 3: Start the backend ---
echo ""
echo "📋 Step 3/4: Starting SwarmSRE Control Plane backend..."
if [ -d "$CONTROL_PLANE_DIR" ]; then
    cd "$CONTROL_PLANE_DIR"
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        uvicorn main:app --reload --port 8000 &
        BACKEND_PID=$!
        echo "✅ Backend started (PID: $BACKEND_PID)"
        sleep 2
    else
        echo "⚠️  Python venv not found. Start backend manually:"
        echo "   cd ${CONTROL_PLANE_DIR} && source .venv/bin/activate && uvicorn main:app --reload"
    fi
else
    echo "⚠️  Control plane not found at ${CONTROL_PLANE_DIR}."
    echo "   Start backend manually."
fi

# --- Step 4: Inject chaos ---
echo ""
echo "═══════════════════════════════════════════════"
echo "  🎯 Ready to inject chaos!"
echo ""
echo "  Open the dashboard at: http://localhost:5173"
echo "  (or http://localhost:8000 if using production build)"
echo ""
echo "  Press ENTER when the audience is watching..."
echo "═══════════════════════════════════════════════"
read -r

bash "${DIR}/inject-faults.sh"

echo ""
echo "═══════════════════════════════════════════════"
echo "  🎬 Demo is LIVE! Watch the dashboard for:"
echo "  1. Incident detection (CrashLoopBackOff)"
echo "  2. Multi-agent Root Cause Analysis"
echo "  3. Proposed YAML patch"
echo "  4. Click 'APPROVE FIX' to self-heal!"
echo "═══════════════════════════════════════════════"

# Cleanup trap
if [ -n "$BACKEND_PID" ]; then
    echo ""
    echo "Press ENTER to stop the backend and clean up..."
    read -r
    kill $BACKEND_PID 2>/dev/null || true
    bash "${DIR}/reset-demo.sh"
fi
