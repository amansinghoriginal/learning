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
# Building Comfort Tutorial Cleanup Script
# This script removes the Building Comfort tutorial applications from your Kubernetes cluster

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
    echo -e "${INFO}=== Building Comfort Tutorial Cleanup ===${NC}"
    echo
}

remove_tutorial_resources() {
    print_info "Removing Building Comfort tutorial resources..."
    
    # Remove ingress routes if they exist
    print_info "Removing ingress routes..."
    kubectl delete ingressroute dashboard-ingress demo-ingress control-panel-ingress 2>/dev/null || true
    kubectl delete middleware strip-dashboard-prefix strip-demo-prefix strip-control-panel-prefix -n traefik 2>/dev/null || true
    
    # Remove applications
    print_info "Removing applications..."
    kubectl delete deployment dashboard demo control-panel 2>/dev/null || true
    kubectl delete service dashboard demo control-panel 2>/dev/null || true
    
    # Remove database
    print_info "Removing PostgreSQL database..."
    kubectl delete deployment postgres 2>/dev/null || true
    kubectl delete service postgres 2>/dev/null || true
    kubectl delete configmap postgres-init-scripts 2>/dev/null || true
    kubectl delete pvc postgres-pvc 2>/dev/null || true
    
    # Remove all resources by label
    print_info "Removing any remaining resources by label..."
    kubectl delete all -l app=building-comfort 2>/dev/null || true
    
    print_success "Tutorial resources removed"
}

show_completion() {
    echo
    print_success "Building Comfort tutorial cleanup complete!"
    echo
    print_info "Thank you for trying the Building Comfort tutorial."
    print_info "For more information, visit: https://drasi.io"
    echo
}

# Main execution
show_header

echo -n "This will remove all Building Comfort tutorial resources. Continue? (y/n): "
read -r response

if [[ "$response" != "y" ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

remove_tutorial_resources
show_completion