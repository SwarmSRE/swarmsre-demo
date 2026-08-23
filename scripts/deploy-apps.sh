#!/bin/bash
# deploy-apps.sh — Deploy the 3-service demo topology into the demo namespace
set -e

echo "═══════════════════════════════════════════════"
echo "  SwarmSRE Demo App Deployment"
echo "═══════════════════════════════════════════════"

# Ensure demo namespace exists
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
# ─── API Gateway ───────────────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: demo
  labels:
    app: api-gateway
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
        tier: frontend
    spec:
      containers:
      - name: api-gateway
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: demo
spec:
  selector:
    app: api-gateway
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
# ─── Backend Service ───────────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-service
  namespace: demo
  labels:
    app: backend-service
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-service
  template:
    metadata:
      labels:
        app: backend-service
        tier: backend
    spec:
      containers:
      - name: backend-service
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: demo
spec:
  selector:
    app: backend-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
# ─── Payment Service (Chaos Target) ───────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: demo
  labels:
    app: payment-service
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
        tier: backend
    spec:
      containers:
      - name: payment-service
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: demo
spec:
  selector:
    app: payment-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

echo ""
echo "⏳ Waiting for all deployments to be ready..."
kubectl wait --for=condition=Available=True deployment/api-gateway -n demo --timeout=60s
kubectl wait --for=condition=Available=True deployment/backend-service -n demo --timeout=60s
kubectl wait --for=condition=Available=True deployment/payment-service -n demo --timeout=60s

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Demo Apps Deployed Successfully!"
echo "═══════════════════════════════════════════════"
kubectl get pods -n demo
