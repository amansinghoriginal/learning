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
# Curbside Pickup Tutorial Cleanup Script
# This script removes the Curbside Pickup tutorial applications from your Kubernetes cluster

set -euo pipefail

# Colors for output
INFO='\033[0;36m'      # Cyan
SUCCESS='\033[0;32m'   # Green
WARNING='\033[0;33m'   # Yellow
ERROR='\033[0;31m'     # Red
NC='\033[0m'           # No Color

print_info() {
    echo -e "${INFO}[*] $1${NC}"
}

print_success() {
    echo -e "${SUCCESS}[+] $1${NC}"
}

print_warning() {
    echo -e "${WARNING}[!] $1${NC}"
}

print_error() {
    echo -e "${ERROR}[x] $1${NC}"
}

show_header() {
    echo
    echo -e "${INFO}=== Curbside Pickup Tutorial Cleanup ===${NC}"
    echo
}

remove_tutorial_resources() {
    print_info "Removing Curbside Pickup tutorial resources..."
    
    # Remove ingress routes if they exist
    print_info "Removing ingress routes..."
    kubectl delete ingressroute delivery-dashboard-ingress delay-dashboard-ingress demo-ingress physical-ops-ingress retail-ops-ingress 2>/dev/null || true
    kubectl delete middleware strip-delivery-dashboard-prefix strip-delay-dashboard-prefix strip-demo-prefix strip-physical-ops-prefix strip-retail-ops-prefix -n traefik 2>/dev/null || true
    
    # Remove applications
    print_info "Removing applications..."
    kubectl delete deployment delivery-dashboard delay-dashboard demo physical-ops retail-ops 2>/dev/null || true
    kubectl delete service delivery-dashboard delay-dashboard demo physical-ops retail-ops 2>/dev/null || true
    
    # Remove databases
    print_info "Removing PostgreSQL database..."
    kubectl delete deployment postgres 2>/dev/null || true
    kubectl delete service postgres 2>/dev/null || true
    kubectl delete configmap postgres-init-scripts 2>/dev/null || true
    kubectl delete pvc postgres-pvc 2>/dev/null || true
    
    print_info "Removing MySQL database..."
    kubectl delete deployment mysql 2>/dev/null || true
    kubectl delete service mysql 2>/dev/null || true
    kubectl delete configmap mysql-init-scripts 2>/dev/null || true
    kubectl delete pvc mysql-pvc 2>/dev/null || true
    
    # Remove all resources by label
    print_info "Removing any remaining resources by label..."
    kubectl delete all -l app=curbside-pickup 2>/dev/null || true
    
    print_success "Tutorial resources removed"
}

show_completion() {
    echo
    print_success "Curbside Pickup tutorial cleanup complete!"
    echo
    print_info "Thank you for trying the Curbside Pickup tutorial."
    print_info "For more information, visit: https://drasi.io"
    echo
}

# Main execution
show_header

echo -n "This will remove all Curbside Pickup tutorial resources. Continue? (y/n): "
read -r response

if [[ "$response" != "y" ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

remove_tutorial_resources
show_completion