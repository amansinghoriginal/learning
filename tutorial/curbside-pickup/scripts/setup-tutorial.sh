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

#!/bin/bash
# Curbside Pickup Tutorial Setup Script
# This script deploys the Curbside Pickup tutorial applications to your Kubernetes cluster

set -euo pipefail

# Get script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUTORIAL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$TUTORIAL_DIR")")"

# Colors for output
INFO='\033[0;36m'      # Cyan
SUCCESS='\033[0;32m'   # Green
WARNING='\033[0;33m'   # Yellow
ERROR='\033[0;31m'     # Red
NC='\033[0m'           # No Color

print_info() {
    printf "${INFO}[*] %s${NC}\n" "$1"
}

print_success() {
    printf "${SUCCESS}[+] %s${NC}\n" "$1"
}

print_warning() {
    printf "${WARNING}[!] %s${NC}\n" "$1"
}

print_error() {
    printf "${ERROR}[x] %s${NC}\n" "$1"
}

show_header() {
    echo
    printf "${INFO}=== Curbside Pickup Tutorial Setup ===${NC}\n"
    echo
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Portable timeout function using perl (available on all Linux and macOS systems)
timeout_command() {
    local duration=$1
    shift
    
    # Run command with timeout using perl
    perl -e '
        $SIG{ALRM} = sub { die "timeout\n" };
        alarm shift;
        $ret = system(@ARGV);
        alarm 0;
        exit($ret >> 8);
    ' "$duration" "$@"
}

test_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command_exists kubectl; then
        print_error "kubectl not found. Install from https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    print_success "kubectl: OK"
    
    # Check cluster connection
    print_info "Checking Kubernetes cluster connection..."
    timeout_command 20s kubectl cluster-info >/dev/null 2>&1
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Check if it was a timeout (exit code 255 from our perl script when it dies)
        if [ $exit_code -eq 255 ]; then
            print_error "Cannot connect to Kubernetes cluster (timeout after 20 seconds)"
            print_error "Please ensure you have a k3d cluster running:"
            print_error "  k3d cluster create drasi-tutorial -p '8123:80@loadbalancer'"
            echo
            print_error "Or check your kubectl context:"
            print_error "  kubectl config current-context"
        else
            print_error "No Kubernetes cluster found or connection failed"
            print_error "Please create a k3d cluster first:"
            print_error "  k3d cluster create drasi-tutorial -p '8123:80@loadbalancer'"
        fi
        exit 1
    fi
    print_success "cluster: OK"
    
    # Check drasi CLI
    if ! command_exists drasi; then
        print_error "drasi CLI not found. Install from https://drasi.io/reference/command-line-interface/#get-the-drasi-cli"
        exit 1
    fi
    print_success "drasi: OK"
}

initialize_drasi() {
    print_info "Checking Drasi installation..."
    
    # Check if drasi-system namespace exists
    if kubectl get namespace drasi-system >/dev/null 2>&1; then
        print_success "Drasi is already initialized"
    else
        print_warning "Drasi is not initialized"
        echo -n "Initialize Drasi now? (y/n): "
        read -r response
        
        if [[ "$response" != "y" ]]; then
            print_warning "Skipping Drasi initialization. You can run 'drasi init' manually later."
            print_warning "Note: Drasi resources deployment will be skipped."
            return 1
        fi
        
        print_info "Initializing Drasi..."
        
        # Configure drasi environment
        if ! drasi env kube; then
            print_error "Failed to configure Drasi environment"
            exit 1
        fi
        
        # Try to initialize Drasi (up to 3 attempts)
        max_attempts=3
        for i in $(seq 1 $max_attempts); do
            print_info "Initialization attempt $i of $max_attempts..."
            
            if drasi init; then
                print_success "Drasi initialized successfully"
                sleep 10  # Give resources time to create
                break
            fi
            
            if [ $i -lt $max_attempts ]; then
                print_warning "Initialization failed, cleaning up and retrying..."
                drasi uninstall -y >/dev/null 2>&1 || true
                sleep 5
            else
                print_error "Failed to initialize Drasi after $max_attempts attempts"
                exit 1
            fi
        done
    fi
    
    # Verify Drasi is working
    print_info "Verifying Drasi installation..."
    if ! drasi list source >/dev/null 2>&1; then
        print_error "Drasi installation failed. Please check logs."
        exit 1
    fi
    print_success "Drasi is ready"
    return 0
}

deploy_databases() {
    print_info "Deploying databases..."
    
    cd "$TUTORIAL_DIR"
    
    # Deploy PostgreSQL
    print_info "Deploying PostgreSQL database..."
    if ! kubectl apply -f retail-ops/k8s/postgres-database.yaml; then
        print_error "Failed to deploy PostgreSQL"
        exit 1
    fi
    
    # Deploy MySQL
    print_info "Deploying MySQL database..."
    if ! kubectl apply -f physical-ops/k8s/mysql-database.yaml; then
        print_error "Failed to deploy MySQL"
        exit 1
    fi
    
    # Wait for databases to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    if ! kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi
    print_success "PostgreSQL: Ready"
    
    print_info "Waiting for MySQL to be ready..."
    if ! kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s; then
        print_error "MySQL failed to start"
        exit 1
    fi
    print_success "MySQL: Ready"
}

deploy_applications() {
    print_info "Deploying applications..."
    
    cd "$TUTORIAL_DIR"
    
    # Deploy all applications
    kubectl apply -f delivery-dashboard/k8s/deployment.yaml
    kubectl apply -f delay-dashboard/k8s/deployment.yaml
    kubectl apply -f demo/k8s/deployment.yaml
    kubectl apply -f physical-ops/k8s/deployment.yaml
    kubectl apply -f retail-ops/k8s/deployment.yaml
    
    # Wait for deployments to be ready
    print_info "Waiting for applications to be ready..."
    
    apps=("delivery-dashboard" "delay-dashboard" "demo" "physical-ops" "retail-ops")
    for app in "${apps[@]}"; do
        if kubectl wait --for=condition=available deployment/$app --timeout=300s; then
            print_success "$app: Ready"
        else
            print_error "$app: Failed to start"
            exit 1
        fi
    done
}

setup_ingress() {
    print_info "Checking for Traefik v2.x ingress controller..."
    
    # Check if Traefik CRDs exist (v2.x uses traefik.containo.us)
    if ! kubectl get crd ingressroutes.traefik.containo.us >/dev/null 2>&1; then
        print_warning "Traefik v2.x not found. Skipping ingress setup."
        return 1
    fi
    
    print_info "Attempting to deploy ingress routes..."
    cd "$TUTORIAL_DIR"
    
    # Try to deploy ingress routes
    ingress_failed=false
    kubectl apply -f delivery-dashboard/k8s/ingress.yaml >/dev/null 2>&1 || ingress_failed=true
    kubectl apply -f delay-dashboard/k8s/ingress.yaml >/dev/null 2>&1 || ingress_failed=true
    kubectl apply -f demo/k8s/ingress.yaml >/dev/null 2>&1 || ingress_failed=true
    kubectl apply -f physical-ops/k8s/ingress.yaml >/dev/null 2>&1 || ingress_failed=true
    kubectl apply -f retail-ops/k8s/ingress.yaml >/dev/null 2>&1 || ingress_failed=true
    
    if [ "$ingress_failed" = false ]; then
        print_success "Ingress routes configured"
        return 0
    else
        print_warning "Some ingress routes failed to deploy"
        return 1
    fi
}

show_access_instructions() {
    local use_ingress=$1
    
    echo
    print_success "Setup complete!"
    echo
    
    if [ "$use_ingress" -eq 0 ]; then
        print_info "Access the applications at:"
        echo "  - Demo (All Apps):    http://localhost:8123/"
        echo "  - Physical Ops:       http://localhost:8123/physical-ops"
        echo "  - Retail Ops:         http://localhost:8123/retail-ops"
        echo "  - Delivery Dashboard: http://localhost:8123/delivery-dashboard"
        echo "  - Delay Dashboard:    http://localhost:8123/delay-dashboard"
        echo "  - Physical Ops API:   http://localhost:8123/physical-ops/docs"
        echo "  - Retail Ops API:     http://localhost:8123/retail-ops/docs"
        echo
        print_info "Note: This assumes your k3d cluster was created with port mapping 8123:80"
    else
        print_info "Ingress not configured. Use one of these options:"
        echo
        echo "Option 1: Configure ingress manually (if you have Traefik or another ingress controller)"
        echo
        echo "Option 2: Use port-forwarding to access the applications:"
        echo "  - Delivery Dashboard: kubectl port-forward svc/delivery-dashboard 3000:3000"
        echo "  - Delay Dashboard:    kubectl port-forward svc/delay-dashboard 3001:3000"
        echo "  - Demo Portal:        kubectl port-forward svc/demo 3002:3000"
        echo "  - Physical Ops:       kubectl port-forward svc/physical-ops 8003:8003"
        echo "  - Retail Ops:         kubectl port-forward svc/retail-ops 8004:8004"
    fi
    
    echo
    print_info "Next steps:"
    echo "  1. Deploy Drasi resources: cd tutorial/curbside-pickup/drasi"
    echo "  2. Apply sources, queries, and reactions"
    echo
}

# Main execution
show_header
test_prerequisites

# Try to initialize Drasi but continue even if user declines
drasi_initialized=0
if initialize_drasi; then
    drasi_initialized=1
fi

deploy_databases
deploy_applications

if setup_ingress; then
    use_ingress=0
else
    use_ingress=1
fi

show_access_instructions $use_ingress

# Additional warning if Drasi wasn't initialized
if [ $drasi_initialized -eq 0 ]; then
    echo
    print_warning "Remember: Drasi was not initialized. The tutorial applications are deployed,"
    print_warning "but you'll need to run 'drasi init' manually before deploying Drasi resources."
fi