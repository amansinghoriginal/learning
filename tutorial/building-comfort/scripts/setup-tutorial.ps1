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

# Setup script for Building Comfort tutorial (Windows PowerShell version)
#Requires -Version 5.1

param(
    [string]$K3dVersion = "v5.6.0"
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Navigate up from scripts -> building-comfort -> tutorial -> learning
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))

# Source shared functions
. "$ProjectRoot\scripts\setup-functions.ps1"

# Check for Administrator privileges (required for software installation)
Require-Administrator

# Display header
Show-Header -TutorialName "Building Comfort"

# Select deployment mode
$DeploymentMode = Select-DeploymentMode
Write-Info "Selected mode: $DeploymentMode"

# Track whether we can deploy ingresses
$DeployIngress = "false"

if ($DeploymentMode -eq "k3d") {
    # Step 1: Check kubectl
    Test-Kubectl
    
    # Step 2: Check for k3d
    Write-Info "Checking for k3d..."
    $K3dClusterCreated = $false
    
    if (Test-K3d -RequiredVersion $K3dVersion) {
        # Check for existing clusters
        Write-Info "Checking for existing k3d clusters..."
        try {
            $clusters = k3d cluster list -o json 2>$null | ConvertFrom-Json
            $clusterNames = $clusters | ForEach-Object { $_.name }
        }
        catch {
            $clusterNames = @()
        }
        
        if ($clusterNames.Count -eq 0) {
            Write-Info "No k3d clusters found."
            if (Read-UserChoice "Would you like to create a new k3d cluster?") {
                Write-Info "Creating k3d cluster 'drasi-tutorial'..."
                k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                Write-Success "k3d cluster created successfully"
                $K3dClusterCreated = $true
                $SelectedCluster = "drasi-tutorial"
            }
            else {
                Write-Error "k3d cluster is required for this mode"
                exit 1
            }
        }
        else {
            # List available clusters
            Write-Info "Available k3d clusters:"
            for ($i = 0; $i -lt $clusterNames.Count; $i++) {
                Write-Host "  $($i + 1). $($clusterNames[$i])" -ForegroundColor White
            }
            
            # Select cluster
            if ($clusterNames.Count -eq 1) {
                $SelectedCluster = $clusterNames[0]
                Write-Info "Using cluster: $SelectedCluster"
            }
            else {
                # Pick first as default
                $defaultCluster = $clusterNames[0]
                $selection = Read-Host "Select cluster number (default: 1 - $defaultCluster)"
                
                if ([string]::IsNullOrWhiteSpace($selection)) {
                    $SelectedCluster = $defaultCluster
                }
                else {
                    try {
                        $index = [int]$selection - 1
                        if ($index -ge 0 -and $index -lt $clusterNames.Count) {
                            $SelectedCluster = $clusterNames[$index]
                        }
                        else {
                            Write-Warning "Invalid selection. Using default: $defaultCluster"
                            $SelectedCluster = $defaultCluster
                        }
                    }
                    catch {
                        Write-Warning "Invalid selection. Using default: $defaultCluster"
                        $SelectedCluster = $defaultCluster
                    }
                }
            }
        }
        
        # Set kubectl context to the selected cluster
        Write-Info "Switching kubectl context to k3d cluster..."
        kubectl config use-context "k3d-$SelectedCluster"
        
        # Check if Traefik is available
        if (Test-Traefik) {
            $DeployIngress = "true"
            Write-Success "Traefik is available, ingress will be deployed"
        }
        else {
            Write-Warning "Traefik is not available, will use port-forwarding instead"
        }
    }
    else {
        Write-Error "k3d is required for this tutorial"
        exit 1
    }
    
    # Step 3: Check for Drasi CLI
    Test-DrasiCLI
    
    # Step 4: Initialize Drasi
    if (Read-UserChoice "Would you like to initialize Drasi now?") {
        Initialize-Drasi -MaxAttempts 3
    }
    else {
        Write-Warning "Skipping Drasi initialization"
        Write-Info "You will need to run 'drasi init' manually before applying Drasi resources"
    }
}
else {
    # Apps-only mode
    Write-Info "Apps-only mode selected"
    Write-Info "This mode assumes you have:"
    Write-Info "  - A working Kubernetes cluster"
    Write-Info "  - kubectl configured and connected"
    Write-Info "  - Drasi already installed"
    
    # Check kubectl connection
    Test-Kubectl
    
    Write-Warning "Ingress will not be deployed in apps-only mode"
    Write-Info "You will need to use port-forwarding to access the applications"
}

Write-Host ""
Write-Info "Starting application deployment..."
Write-Host ""

# Deploy database
Write-Info "Deploying PostgreSQL database..."
kubectl apply -f "$ScriptDir\..\postgres\k8s\postgres-database.yaml"
Wait-ForDeployment -DeploymentName "postgres" -Timeout 300

Write-Success "Database is ready. Deploying applications..."

# Deploy applications
# Deploy dashboard and demo first (no DB dependencies)
Deploy-App -AppName "Dashboard" -Directory "$ScriptDir\..\dashboard\k8s" -DeployIngress $DeployIngress
Deploy-App -AppName "Demo" -Directory "$ScriptDir\..\demo\k8s" -DeployIngress $DeployIngress

# Deploy control panel (has DB dependency)
Deploy-App -AppName "Control Panel" -Directory "$ScriptDir\..\control-panel\k8s" -DeployIngress $DeployIngress

# Wait for all deployments to be ready
Write-Info "Waiting for all applications to be ready..."
$apps = @("dashboard", "demo", "control-panel")
foreach ($app in $apps) {
    Wait-ForDeployment -DeploymentName $app
}

Write-Success "All applications deployed successfully!"

# Show access instructions
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

if ($DeployIngress -eq "true") {
    Write-Host "[SUCCESS] Setup Complete! Access your applications at:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Demo Portal:    http://localhost:8123/" -ForegroundColor Cyan
    Write-Host "  Control Panel:  http://localhost:8123/control-panel" -ForegroundColor Cyan
    Write-Host "  Dashboard:      http://localhost:8123/dashboard" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  The Demo Portal shows both the dashboard and control panel in a single view." -ForegroundColor Gray
}
else {
    Write-Host "[SUCCESS] Setup Complete! To access your applications, use port-forwarding:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Demo Portal:" -ForegroundColor Cyan
    Write-Host "    kubectl port-forward svc/demo 8080:80" -ForegroundColor Yellow
    Write-Host "    Access at: http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Other applications can be accessed similarly:" -ForegroundColor Cyan
    Write-Host "    kubectl port-forward svc/control-panel 8081:80" -ForegroundColor Yellow
    Write-Host "    kubectl port-forward svc/dashboard 8082:80" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[NEXT] Steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to the drasi directory: cd drasi" -ForegroundColor White
Write-Host "  2. Apply Drasi source:" -ForegroundColor White
Write-Host "     drasi apply -f source-facilities.yaml" -ForegroundColor Gray
Write-Host "  3. Apply Drasi queries:" -ForegroundColor White
Write-Host "     drasi apply -f query-ui.yaml" -ForegroundColor Gray
Write-Host "     drasi apply -f query-comfort-calc.yaml" -ForegroundColor Gray
Write-Host "     drasi apply -f query-alert.yaml" -ForegroundColor Gray
Write-Host "  4. Apply SignalR reaction:" -ForegroundColor White
Write-Host "     drasi apply -f reaction-signalr.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "[IMPORTANT] For the dashboard to work:" -ForegroundColor Yellow
Write-Host "  - The SignalR reaction service must be accessible on port 8080" -ForegroundColor White
Write-Host "  - You may need to run: kubectl port-forward -n drasi-system svc/building-signalr-hub-gateway 8080:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""