#!/bin/bash
set -e

# This script provides a foolproof, one-click method to deploy the Kafka cluster
# after all configurations have been finalized. It ensures a clean slate by
# deleting old resources before applying the new configuration.

echo "STEP 1: Building and pushing the final, clean Docker image..."
docker buildx build --platform linux/amd64 -t crpi-umhpg8dvg5qptjum.cn-beijing.personal.cr.aliyuncs.com/prod-scoox/kafka:4.0.0-4 -f kafka/Dockerfile . --load
docker push crpi-umhpg8dvg5qptjum.cn-beijing.personal.cr.aliyuncs.com/prod-scoox/kafka:4.0.0-4

echo "STEP 2: Cleaning up any old Kubernetes resources..."
kubectl delete kafka kafka-cluster -n kafka --ignore-not-found=true
kubectl delete kafkanodepool controller -n kafka --ignore-not-found=true
kubectl delete kafkanodepool broker -n kafka --ignore-not-found=true
kubectl delete pvc -n kafka -l strimzi.io/cluster=kafka-cluster --ignore-not-found=true

echo "Waiting for 15 seconds for resources to terminate..."
sleep 15

echo "STEP 3: Deploying the final configuration..."
kubectl apply -f kafka/kafka-cluster.yaml -n kafka

echo "STEP 4: Tailing logs of the new pods. Press Ctrl+C to exit."
# Wait for pods to be created
sleep 10
kubectl get pods -n kafka -l strimzi.io/cluster=kafka-cluster -w

echo "Deployment finished."