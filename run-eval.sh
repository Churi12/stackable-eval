#!/usr/bin/env bash
# Reproduce the eval: deploy the Stackable Spark operator stack on a local
# minikube cluster and run the SparkPi example end to end.
set -euo pipefail

minikube start --driver=docker --cpus=4 --memory=6144

helm repo add stackable-stable https://repo.stackable.tech/repository/helm-stable/
helm repo update

VERSION=25.3.0
for op in commons-operator secret-operator listener-operator spark-k8s-operator; do
  helm install "$op" "stackable-stable/$op" --wait --version "$VERSION"
done

kubectl apply -f spark-pi-eval.yaml

echo "Watch progress with: kubectl get pods -w"
echo "Once the driver pod shows Completed, check its logs for 'Pi is roughly ...':"
echo "  kubectl logs -l spark-role=driver --tail=30"
