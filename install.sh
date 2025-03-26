#!/bin/bash

ARGOCD_VERSION="v2.14.8"
ARGOCD_NAMESPACE="argocd"

export KUBECONFIG=$PWD/.kubeconfig

# Install cluster
kind create cluster --config config.yaml --kubeconfig .kubeconfig  --wait 300s

# Update kubeconfig to use argocd namespace as default
kubectl config  set-context --current --namespace $ARGOCD_NAMESPACE

# Install ArgoCD
kubectl create namespace $ARGOCD_NAMESPACE
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

# Wait for the argocd server to become ready
kubectl -n $ARGOCD_NAMESPACE wait pod -l app.kubernetes.io/name=argocd-server --for=condition=Ready

# Extract the admin passowrd
echo -n "Admin password: "
kubectl -n $ARGOCD_NAMESPACE get secrets -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Port forward
kubectl -n $ARGOCD_NAMESPACE port-forward svc/argocd-server 8443:443 &
open -a "Google Chrome" "https://localhost:8443/"