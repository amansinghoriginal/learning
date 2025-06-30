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
# Setup script for Building Comfort tutorial

set -e

# Define k3d version to use across all environments
K3D_VERSION="v5.6.0"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source shared functions
source "$PROJECT_ROOT/scripts/setup-functions.sh"

# Display header
show_header "Building Comfort"

# Select deployment mode
DEPLOYMENT_MODE=$(select_deployment_mode)
print_info "Selected mode: $DEPLOYMENT_MODE"

# Track whether we can deploy ingresses
DEPLOY_INGRESS="false"

if [ "$DEPLOYMENT_MODE" = "k3d" ]; then
    # Step 1: Check kubectl
    check_kubectl
    
    # Step 2: Check for k3d
    print_info "Checking for k3d..."
    K3D_CLUSTER_CREATED="false"
    
    if command_exists k3d; then
        INSTALLED_VERSION=$(k3d version 2>/dev/null | grep "k3d version" | sed 's/k3d version //' || echo "unknown")
        print_success "k3d is installed (version: ${INSTALLED_VERSION})"
        
        # Check if it's the expected version
        if [[ "$INSTALLED_VERSION" != *"$K3D_VERSION"* && "$INSTALLED_VERSION" != "unknown" ]]; then
            print_warning "Note: This tutorial was tested with k3d ${K3D_VERSION}"
            print_warning "You have ${INSTALLED_VERSION} installed. Some features may work differently."
        fi
        
        # Check for existing clusters
        print_info "Checking for existing k3d clusters..."
        CLUSTERS=$(k3d cluster list -o json 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "")
        
        # Check specifically for drasi-tutorial cluster
        if echo "$CLUSTERS" | grep -q "^drasi-tutorial$"; then
            # Found drasi-tutorial cluster - ask what to do
            print_info "Found existing 'drasi-tutorial' k3d cluster"
            echo ""
            echo -e "${YELLOW}What would you like to do?${NC}"
            echo "  1. Delete and recreate cluster (default)"
            echo "  2. Use existing cluster (may have conflicts)"
            echo "  3. Stop script execution"
            echo ""
            
            read -p "Enter your choice [1-3] (default: 1): " CHOICE
            if [ -z "$CHOICE" ]; then
                CHOICE="1"
            fi
            
            case $CHOICE in
                1)
                    # Delete and recreate
                    print_info "Deleting existing 'drasi-tutorial' cluster..."
                    k3d cluster delete drasi-tutorial
                    print_success "Cluster deleted"
                    
                    print_info "Creating new k3d cluster 'drasi-tutorial'..."
                    k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                    print_success "k3d cluster created successfully"
                    K3D_CLUSTER_CREATED="true"
                    SELECTED_CLUSTER="drasi-tutorial"
                    ;;
                2)
                    # Use existing cluster
                    print_warning "Using existing cluster may cause conflicts with existing resources"
                    SELECTED_CLUSTER="drasi-tutorial"
                    print_info "Using existing cluster: drasi-tutorial"
                    ;;
                3)
                    print_info "Setup cancelled by user"
                    exit 0
                    ;;
                *)
                    print_warning "Invalid choice. Defaulting to option 1 (delete and recreate)"
                    # Delete and recreate
                    print_info "Deleting existing 'drasi-tutorial' cluster..."
                    k3d cluster delete drasi-tutorial
                    print_success "Cluster deleted"
                    
                    print_info "Creating new k3d cluster 'drasi-tutorial'..."
                    k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                    print_success "k3d cluster created successfully"
                    K3D_CLUSTER_CREATED="true"
                    SELECTED_CLUSTER="drasi-tutorial"
                    ;;
            esac
        else
            # No drasi-tutorial cluster found - just create it
            print_info "Creating k3d cluster 'drasi-tutorial'..."
            k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
            print_success "k3d cluster created successfully"
            K3D_CLUSTER_CREATED="true"
            SELECTED_CLUSTER="drasi-tutorial"
        fi
    else
        print_warning "k3d is not installed"
        if ask_user "Would you like to install k3d ${K3D_VERSION}?"; then
            print_info "Installing k3d ${K3D_VERSION}..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                # Always use the install script to ensure we get the specific version
                curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=${K3D_VERSION} bash
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                # Linux
                curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=${K3D_VERSION} bash
            else
                print_error "Unsupported OS. Please install k3d manually."
                exit 1
            fi
            
            if command_exists k3d; then
                print_success "k3d installed successfully"
                
                # Create cluster
                if ask_user "Would you like to create a new k3d cluster?"; then
                    print_info "Creating k3d cluster 'drasi-tutorial'..."
                    k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                    print_success "k3d cluster created successfully"
                    K3D_CLUSTER_CREATED="true"
                    SELECTED_CLUSTER="drasi-tutorial"
                else
                    print_error "k3d cluster is required for this mode"
                    exit 1
                fi
            else
                print_error "k3d installation failed"
                exit 1
            fi
        else
            print_error "k3d is required for this mode"
            exit 1
        fi
    fi
    
    # Step 3: Handle Kubernetes context
    # If we selected a k3d cluster, ensure we're using it
    if [ -n "$SELECTED_CLUSTER" ]; then
        EXPECTED_CONTEXT="k3d-$SELECTED_CLUSTER"
        CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
        
        if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
            print_info "Switching to k3d cluster context: $EXPECTED_CONTEXT"
            kubectl config use-context "$EXPECTED_CONTEXT"
        else
            print_success "Already using k3d cluster context: $EXPECTED_CONTEXT"
        fi
        
        # Verify cluster is accessible
        print_info "Verifying cluster connection..."
        if ! kubectl cluster-info >/dev/null 2>&1; then
            print_error "Cannot connect to k3d cluster"
            print_info "Please check if the cluster is running: k3d cluster list"
            exit 1
        fi
        print_success "Connected to k3d cluster successfully"
    fi
    
    # Step 4: Check Traefik
    if check_traefik; then
        DEPLOY_INGRESS="true"
        print_success "Will deploy applications with ingress routing"
    else
        DEPLOY_INGRESS="false"
        print_warning "Will deploy applications without ingress routing"
    fi
    
    # Step 5: Check for Drasi CLI
    check_drasi_cli || exit 1
    
    # Step 6: Initialize Drasi (includes Dapr installation)
    print_info "Checking if Drasi is already installed..."
    if drasi list source 2>&1 | grep -i "error" >/dev/null; then
        print_info "Drasi is not installed or not functioning properly"
        init_drasi || exit 1
    else
        print_success "Drasi is already installed and functioning"
    fi
    
else
    # Apps-only mode
    print_info "Apps-only mode selected"
    print_info "Assuming Kubernetes cluster and Drasi are already configured"
    
    # Verify kubectl connection
    print_info "Verifying cluster connection..."
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Please ensure kubectl is configured correctly"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # No ingress in apps-only mode
    DEPLOY_INGRESS="false"
fi

# Step 7: Deploy database
print_info "Preparing to deploy PostgreSQL database..."
if ask_user "Would you like to deploy the PostgreSQL database?"; then
    if k8s_resource_exists deployment postgres; then
        print_warning "PostgreSQL is already deployed"
    else
        print_info "Deploying PostgreSQL for Building Comfort..."
        kubectl apply -f "$SCRIPT_DIR/../control-panel/k8s/postgres-database.yaml"
        if ! wait_for_deployment postgres; then
            print_error "Failed to deploy PostgreSQL. Please check the logs and try again."
            exit 1
        fi
    fi
else
    print_warning "Skipping database deployment"
fi

# Step 8: Deploy applications
print_info "Preparing to deploy tutorial applications..."
if ask_user "Would you like to deploy all tutorial applications?"; then
    # Deploy applications
    APPS=(
        "dashboard"
        "demo"
        "control-panel"
    )
    
    # Deploy dashboard and demo first (no DB dependencies)
    for APP in "dashboard" "demo"; do
        if k8s_resource_exists deployment $APP; then
            print_warning "$APP is already deployed"
        else
            print_info "Deploying $APP..."
            deploy_app "$APP" \
                "$SCRIPT_DIR/../$APP/k8s/deployment.yaml" \
                "$SCRIPT_DIR/../$APP/k8s/ingress.yaml" \
                "$DEPLOY_INGRESS"
        fi
    done
    
    # Wait for dashboard and demo to be ready
    print_info "Waiting for dashboard and demo to be ready..."
    wait_for_deployment dashboard
    wait_for_deployment demo
    
    # Deploy control panel (has DB dependency)
    if k8s_resource_exists deployment control-panel; then
        print_warning "control-panel is already deployed"
    else
        print_info "Deploying control-panel..."
        deploy_app "control-panel" \
            "$SCRIPT_DIR/../control-panel/k8s/deployment.yaml" \
            "$SCRIPT_DIR/../control-panel/k8s/ingress.yaml" \
            "$DEPLOY_INGRESS"
    fi
    
    # Wait for all deployments
    print_info "Waiting for all applications to be ready..."
    FAILED_APPS=()
    for APP in "${APPS[@]}"; do
        if ! wait_for_deployment $APP; then
            FAILED_APPS+=("$APP")
        fi
    done
    
    if [ ${#FAILED_APPS[@]} -gt 0 ]; then
        print_error "The following applications failed to deploy: ${FAILED_APPS[*]}"
        print_info "Please check the logs and deploy them manually."
        exit 1
    fi
else
    print_warning "Skipping application deployment"
fi

# Display completion message
show_completion

# Display access instructions
print_info "To access the applications:"
echo ""

if [ "$DEPLOY_INGRESS" = "true" ]; then
    echo "Applications are available at:"
    echo "   - Demo: http://localhost:8123/"
    echo "   - Control Panel: http://localhost:8123/control-panel"
    echo "   - Dashboard: http://localhost:8123/dashboard"
    echo ""
    echo "API Documentation:"
    echo "   - Swagger UI: http://localhost:8123/control-panel/docs"
    echo "   - ReDoc: http://localhost:8123/control-panel/redoc"
else
    echo "Use kubectl port-forward to access individual services:"
    echo "   kubectl port-forward svc/demo 8080:80"
    echo "   kubectl port-forward svc/control-panel 8081:80"
    echo "   kubectl port-forward svc/dashboard 8082:80"
fi

echo ""
print_success "Happy learning!"