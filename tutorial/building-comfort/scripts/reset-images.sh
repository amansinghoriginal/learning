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
# Reset app deployment to use official GHCR images

set -e

# Get script and tutorial directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUTORIAL_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <app-name>"
    echo "Available apps: control-panel, dashboard, demo"
    echo ""
    echo "To reset all apps, run: $0 all"
    exit 1
fi

APP=$1

# Function to reset a single app
reset_app() {
    local app=$1
    echo "Resetting $app to use official GHCR image..."
    
    kubectl set image deployment/$app $app=ghcr.io/drasi-project/learning/building-comfort/$app:latest
    kubectl patch deployment $app -p '{"spec":{"template":{"spec":{"containers":[{"name":"'$app'","imagePullPolicy":"Always"}]}}}}'
    
    echo "Restarting $app deployment..."
    kubectl rollout restart deployment/$app
    kubectl rollout status deployment/$app
    
    echo "$app reset to official image successfully!"
}

# Handle 'all' option
if [ "$APP" = "all" ]; then
    APPS=("control-panel" "dashboard" "demo")
    for app in "${APPS[@]}"; do
        reset_app $app
    done
    echo "All apps have been reset to official images!"
else
    # Validate app name
    VALID_APPS=("control-panel" "dashboard" "demo")
    if [[ ! " ${VALID_APPS[@]} " =~ " ${APP} " ]]; then
        echo "Error: Invalid app name '$APP'"
        echo "Available apps: ${VALID_APPS[@]}"
        exit 1
    fi
    
    reset_app $APP
fi