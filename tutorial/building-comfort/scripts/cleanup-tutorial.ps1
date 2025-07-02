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

#!/usr/bin/env pwsh
# Building Comfort Tutorial Cleanup Script
# This script removes the Building Comfort tutorial applications from your Kubernetes cluster

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Output functions with color
function Write-Info($message) {
    Write-Host "[*] $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "[+] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[!] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[x] $message" -ForegroundColor Red
}

function Show-Header {
    Write-Host ""
    Write-Host "=== Building Comfort Tutorial Cleanup ===" -ForegroundColor Cyan
    Write-Host ""
}

function Remove-TutorialResources {
    Write-Info "Removing Building Comfort tutorial resources..."
    
    # Remove ingress routes if they exist
    Write-Info "Removing ingress routes..."
    kubectl delete ingressroute dashboard-ingress demo-ingress control-panel-ingress 2>&1 | Out-Null
    kubectl delete middleware strip-dashboard-prefix strip-demo-prefix strip-control-panel-prefix -n traefik 2>&1 | Out-Null
    
    # Remove applications
    Write-Info "Removing applications..."
    kubectl delete deployment dashboard demo control-panel 2>&1 | Out-Null
    kubectl delete service dashboard demo control-panel 2>&1 | Out-Null
    
    # Remove database
    Write-Info "Removing PostgreSQL database..."
    kubectl delete deployment postgres 2>&1 | Out-Null
    kubectl delete service postgres 2>&1 | Out-Null
    kubectl delete configmap postgres-init-scripts 2>&1 | Out-Null
    kubectl delete pvc postgres-pvc 2>&1 | Out-Null
    
    # Remove all resources by label
    Write-Info "Removing any remaining resources by label..."
    kubectl delete all -l app=building-comfort 2>&1 | Out-Null
    
    Write-Success "Tutorial resources removed"
}

function Show-Completion {
    Write-Host ""
    Write-Success "Building Comfort tutorial cleanup complete!"
    Write-Host ""
    Write-Info "Thank you for trying the Building Comfort tutorial."
    Write-Info "For more information, visit: https://drasi.io"
    Write-Host ""
}

# Main execution
Show-Header

$response = Read-Host "This will remove all Building Comfort tutorial resources. Continue? (y/n)"
if ($response -ne 'y') {
    Write-Info "Cleanup cancelled"
    exit 0
}

Remove-TutorialResources
Show-Completion