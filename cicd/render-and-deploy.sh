#!/usr/bin/env bash

set -euo pipefail

export FRONTEND_IMAGE
export BACKEND_IMAGE
NAMESPACE="surgtech-eks"

mkdir -p rendered
envsubst < k8s/all.yml > rendered/all.yml
kubectl apply -f rendered/all.yml
kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=180s
kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=180s
