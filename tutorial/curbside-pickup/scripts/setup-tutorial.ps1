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

# Setup script for Curbside Pickup tutorial (Windows PowerShell version)
#Requires -Version 5.1

param(
    [string]$K3dVersion = "v5.6.0"
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Navigate up from scripts -> curbside-pickup -> tutorial -> learning
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))

# Source shared functions
. "$ProjectRoot\scripts\setup-functions.ps1"

# Check for Administrator privileges (required for software installation)
Require-Administrator

# Display header
Show-Header -TutorialName "Curbside Pickup"

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
            if ($clusters) {
                $clusterNames = @($clusters | ForEach-Object { $_.name })
            }
            else {
                $clusterNames = @()
            }
        }
        catch {
            $clusterNames = @()
        }
        
        # Check specifically for drasi-tutorial cluster
        if ($clusterNames -contains "drasi-tutorial") {
            # Found drasi-tutorial cluster - ask what to do
            Write-Info "Found existing 'drasi-tutorial' k3d cluster"
            Write-Host ""
            Write-Host "What would you like to do?" -ForegroundColor Yellow
            Write-Host "  1. Delete and recreate cluster (default)" -ForegroundColor White
            Write-Host "  2. Use existing cluster (may have conflicts)" -ForegroundColor White
            Write-Host "  3. Stop script execution" -ForegroundColor White
            Write-Host ""
            
            $choice = Read-Host "Enter your choice [1-3] (default: 1)"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = "1"
            }
            
            switch ($choice) {
                "1" {
                    # Delete and recreate
                    Write-Info "Deleting existing 'drasi-tutorial' cluster..."
                    k3d cluster delete drasi-tutorial
                    Write-Success "Cluster deleted"
                    
                    Write-Info "Creating new k3d cluster 'drasi-tutorial'..."
                    k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                    Write-Success "k3d cluster created successfully"
                    $K3dClusterCreated = $true
                    $SelectedCluster = "drasi-tutorial"
                }
                "2" {
                    # Use existing cluster
                    Write-Warning "Using existing cluster may cause conflicts with existing resources"
                    $SelectedCluster = "drasi-tutorial"
                    Write-Info "Using existing cluster: drasi-tutorial"
                }
                "3" {
                    Write-Info "Setup cancelled by user"
                    exit 0
                }
                default {
                    Write-Warning "Invalid choice. Defaulting to option 1 (delete and recreate)"
                    # Delete and recreate
                    Write-Info "Deleting existing 'drasi-tutorial' cluster..."
                    k3d cluster delete drasi-tutorial
                    Write-Success "Cluster deleted"
                    
                    Write-Info "Creating new k3d cluster 'drasi-tutorial'..."
                    k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
                    Write-Success "k3d cluster created successfully"
                    $K3dClusterCreated = $true
                    $SelectedCluster = "drasi-tutorial"
                }
            }
        }
        else {
            # No drasi-tutorial cluster found - just create it
            Write-Info "Creating k3d cluster 'drasi-tutorial'..."
            k3d cluster create drasi-tutorial --port "8123:80@loadbalancer"
            Write-Success "k3d cluster created successfully"
            $K3dClusterCreated = $true
            $SelectedCluster = "drasi-tutorial"
        }
        
        # Set kubectl context to the selected cluster
        Write-Info "Switching kubectl context to k3d cluster..."
        kubectl config use-context "k3d-$SelectedCluster"
        
        # Verify the cluster is accessible
        Write-Info "Verifying cluster connection..."
        try {
            $null = kubectl cluster-info 2>&1
            Write-Success "Successfully connected to cluster"
        }
        catch {
            Write-Error "Cannot connect to the k3d cluster"
            Write-Info "Please check if the k3d cluster is running: k3d cluster list"
            Write-Info "You may need to start it with: k3d cluster start $SelectedCluster"
            exit 1
        }
        
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

# Deploy databases
Write-Info "Deploying PostgreSQL database for Retail Operations..."
kubectl apply -f "$ScriptDir\..\retail-ops\k8s\postgres-database.yaml"
Wait-ForDeployment -DeploymentName "postgres" -Timeout 300

Write-Info "Deploying MySQL database for Physical Operations..."
kubectl apply -f "$ScriptDir\..\physical-ops\k8s\mysql-database.yaml"
Wait-ForDeployment -DeploymentName "mysql" -Timeout 300

# Deploy applications
Write-Success "Databases are ready. Deploying applications..."

# Deploy dashboards first (no DB dependencies)
Deploy-App -AppName "Delivery Dashboard" -Directory "$ScriptDir\..\delivery-dashboard\k8s" -DeployIngress $DeployIngress
Deploy-App -AppName "Delay Dashboard" -Directory "$ScriptDir\..\delay-dashboard\k8s" -DeployIngress $DeployIngress
Deploy-App -AppName "Demo" -Directory "$ScriptDir\..\demo\k8s" -DeployIngress $DeployIngress

# Deploy apps with DB dependencies
Deploy-App -AppName "Physical Operations" -Directory "$ScriptDir\..\physical-ops\k8s" -DeployIngress $DeployIngress
Deploy-App -AppName "Retail Operations" -Directory "$ScriptDir\..\retail-ops\k8s" -DeployIngress $DeployIngress

# Wait for all deployments to be ready
Write-Info "Waiting for all applications to be ready..."
$apps = @("delivery-dashboard", "delay-dashboard", "demo", "physical-ops", "retail-ops")
foreach ($app in $apps) {
    Wait-ForDeployment -DeploymentName $app
}

Write-Success "All applications deployed successfully!"

# Show access instructions
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

if ($DeployIngress -eq "true") {
    Write-Host "Setup Complete! Access your applications at:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Demo Portal:        http://localhost:8123/" -ForegroundColor Cyan
    Write-Host "  Retail Operations:  http://localhost:8123/retail-ops" -ForegroundColor Cyan
    Write-Host "  Physical Operations: http://localhost:8123/physical-ops" -ForegroundColor Cyan
    Write-Host "  Delivery Dashboard: http://localhost:8123/delivery-dashboard" -ForegroundColor Cyan
    Write-Host "  Delay Dashboard:    http://localhost:8123/delay-dashboard" -ForegroundColor Cyan
}
else {
    Write-Host "Setup Complete! To access your applications, use port-forwarding:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Demo Portal:" -ForegroundColor Cyan
    Write-Host "    kubectl port-forward svc/demo 8080:80" -ForegroundColor Yellow
    Write-Host "    Access at: http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Other applications can be accessed similarly:" -ForegroundColor Cyan
    Write-Host "    kubectl port-forward svc/retail-ops 8081:80" -ForegroundColor Yellow
    Write-Host "    kubectl port-forward svc/physical-ops 8082:80" -ForegroundColor Yellow
    Write-Host "    kubectl port-forward svc/delivery-dashboard 8083:80" -ForegroundColor Yellow
    Write-Host "    kubectl port-forward svc/delay-dashboard 8084:80" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to the drasi directory: cd drasi" -ForegroundColor White
Write-Host "  2. Apply Drasi sources:" -ForegroundColor White
Write-Host "     drasi apply -f retail-ops-source.yaml" -ForegroundColor Gray
Write-Host "     drasi apply -f physical-ops-source.yaml" -ForegroundColor Gray
Write-Host "  3. Apply Drasi queries and reactions as shown in the tutorial" -ForegroundColor White
Write-Host ""
Write-Host "Important: For SignalR to work in the dashboards:" -ForegroundColor Yellow
Write-Host "  - The SignalR reaction service must be accessible on port 8080" -ForegroundColor White
Write-Host "  - You may need to run: kubectl port-forward -n drasi-system svc/signalr-gateway 8080:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""