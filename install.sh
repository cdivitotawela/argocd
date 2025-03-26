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
kubectl -n $ARGOCD_NAMESPACE get secrets -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d > .password
echo "====================="
echo "Admin Password"
cat .password
echo
echo "====================="

# Port forward
kubectl -n $ARGOCD_NAMESPACE port-forward svc/argocd-server 8443:443 > /dev/null 2>&1 &

# Login to argocd
_PASSWORD=$(cat .password)
argocd login 127.0.0.1:8443 --username admin --password $_PASSWORD --insecure

# Add repository
git remote get-url origin | grep -q "git@" && {
  GIT_URL=$(git remote get-url origin | sed 's|git@\([^:]*\):\(.*\)|https://\1/\2|g')
} || {
  GIT_URL=(git remote get-url origin)
}

sleep 10
echo "GIT URL: $GIT_URL"
argocd repo add $GIT_URL --name argocd

#open -a "Google Chrome" "https://localhost:8443/"