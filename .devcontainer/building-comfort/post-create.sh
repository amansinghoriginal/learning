#!/bin/bash
# Copyright 2025 The Drasi Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# Load pre-cached images (fast - local I/O)
echo "Loading pre-cached images..."
docker load -i /opt/drasi-images/*.tar &
docker load -i /opt/dapr-images/*.tar &
docker load -i /opt/k3s-images/*.tar &
wait

echo "Creating K3d cluster..."
k3d cluster delete drasi-tutorial 2>/dev/null || true
k3d cluster create drasi-tutorial --port "80:80@loadbalancer"

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=60s

# Import images into k3d cluster
echo "Importing pre-cached images into k3d..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(drasi-project|daprio|rancher/k3s)" | \
    xargs -P 20 -I {} k3d image import {} -c drasi-tutorial

# Deploy tutorial apps
echo "Deploying tutorial applications..."
kubectl apply -f control-panel/k8s/postgres-database.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

kubectl apply -f dashboard/k8s/deployment.yaml
kubectl apply -f dashboard/k8s/ingress.yaml
kubectl apply -f demo/k8s/deployment.yaml
kubectl apply -f demo/k8s/ingress.yaml
kubectl apply -f control-panel/k8s/deployment.yaml
kubectl apply -f control-panel/k8s/ingress.yaml

kubectl wait --for=condition=available deployment --all --timeout=300s

# Initialize Drasi with local images (no downloads!)
echo "Initializing Drasi..."
drasi init --local --version 0.3.4

echo "Setup complete!"