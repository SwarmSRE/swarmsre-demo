# SwarmSRE Demo Environment 🎯

**Local Kubernetes playground for the SwarmSRE hackathon demo at DevOpsDays Cairo 2026.**

This repo contains everything needed to provision a local KinD cluster, deploy sample microservices, and run chaos engineering demos in under 90 seconds.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (Kubernetes in Docker)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

```bash
# 1. Create the KinD cluster with ingress support
./scripts/setup-cluster.sh

# 2. Deploy the 3-service demo topology
./scripts/deploy-apps.sh

# 3. Verify everything is running
kubectl get pods -n demo
```

## Demo Scripts

| Script | Purpose |
|---|---|
| `scripts/setup-cluster.sh` | Idempotent KinD cluster provisioning |
| `scripts/deploy-apps.sh` | Deploy api-gateway, backend-service, payment-service |
| `scripts/inject-faults.sh` | Break payment-service (CrashLoopBackOff) |
| `scripts/reset-demo.sh` | Restore all services to healthy state |
| `scripts/full-demo.sh` | One-click orchestrator for the live presentation |

## Architecture

```
┌─────────────────────────────────────┐
│  KinD Cluster: swarmsre-demo        │
│                                     │
│  ┌─────────────┐  Namespace: demo   │
│  │ api-gateway  │──┐                │
│  └─────────────┘  │                │
│  ┌────────────────┐│                │
│  │ backend-service ├┘                │
│  └────────────────┘                 │
│  ┌─────────────────┐                │
│  │ payment-service  │ ← Chaos target │
│  └─────────────────┘                │
│                                     │
│  Namespace: swarmsre-system         │
│  ┌──────────────────┐               │
│  │ MCP Server (RBAC) │               │
│  └──────────────────┘               │
└─────────────────────────────────────┘
```

## License

Apache-2.0