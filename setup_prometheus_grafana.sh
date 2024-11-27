#!/bin/bash

# Скрипт для установки Prometheus и Grafana в Kubernetes кластер

set -e

# Переменные
NAMESPACE="monitoring"
PROMETHEUS_RELEASE_NAME="prometheus"
GRAFANA_RELEASE_NAME="grafana"
GRAFANA_ADMIN_PASSWORD="admin123"

echo "=== Добавляем репозитории Helm ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "=== Устанавливаем Prometheus ==="
helm install $PROMETHEUS_RELEASE_NAME prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --create-namespace

echo "=== Устанавливаем Grafana ==="
helm install $GRAFANA_RELEASE_NAME grafana/grafana \
  --namespace $NAMESPACE \
  --set adminPassword=$GRAFANA_ADMIN_PASSWORD \
  --set service.type=NodePort

echo "=== Ожидаем запуска подов ==="
kubectl wait --namespace $NAMESPACE \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/name=prometheus \
  --timeout=180s

kubectl wait --namespace $NAMESPACE \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=180s

echo "=== Получаем NodePort Grafana ==="
NODE_PORT=$(kubectl get svc $GRAFANA_RELEASE_NAME -n $NAMESPACE -o=jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "Grafana доступна по адресу: http://$NODE_IP:$NODE_PORT"
echo "Логин: admin"
echo "Пароль: $GRAFANA_ADMIN_PASSWORD"

echo "=== Скрипт завершён! ==="
