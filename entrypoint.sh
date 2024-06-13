#!/bin/sh

echo "${KUBE_CONFIG_DATA}" | base64 -d > kubeconfig
export KUBECONFIG=kubeconfig

# Ejecutar el comando de kubectl pasado como argumento
kubectl $@

# Verificar si el comando anterior fue exitoso
if [ $? -ne 0 ]; then
  echo "kubectl command failed"
  exit 1
fi

# Verificar si la variable PROJECT está definida
if [ -z "$PROJECT" ]; then
  echo "PROJECT variable is not set. Skipping deployment validation."
  exit 0
fi

# Verificar si la variable PROJECT está definida
if [ -z "$NAMESPACE" ]; then
  echo "NAMESPACE variable is not set. Skipping deployment validation."
  exit 0
fi

# Aquí comienza la lógica de espera
ATTEMPTS=0
MAX_ATTEMPTS=20
SLEEP_TIME=30
READY_REPLICAS=0
DESIRED_REPLICAS=$(kubectl get deployment $PROJECT -n default -o jsonpath='{.spec.replicas}')

until [ $READY_REPLICAS -eq $DESIRED_REPLICAS ] || [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; do
  echo "Waiting for all pods to be ready..."
  READY_REPLICAS=$(kubectl get deployment $PROJECT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
  if [ -z "$READY_REPLICAS" ]; then
    READY_REPLICAS=0
  fi
  echo "Ready replicas: $READY_REPLICAS"
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep $SLEEP_TIME
done

if [ $READY_REPLICAS -ne $DESIRED_REPLICAS ]; then
  echo "Deployment did not complete successfully"
  exit 1
fi

echo "Deployment completed successfully"
exit 0
