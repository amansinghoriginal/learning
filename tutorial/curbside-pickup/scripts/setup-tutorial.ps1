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
# Curbside Pickup Tutorial Setup Script
# This script deploys the Curbside Pickup tutorial applications to your Kubernetes cluster

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Get script and project directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TutorialDir = Split-Path -Parent $ScriptDir
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $TutorialDir)

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
    Write-Host "=== Curbside Pickup Tutorial Setup ===" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Command($command) {
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check kubectl
    if (-not (Test-Command "kubectl")) {
        Write-Error "kubectl not found. Install from https://kubernetes.io/docs/tasks/tools/"
        exit 1
    }
    Write-Success "kubectl: OK"
    
    # Check cluster connection
    Write-Info "Checking Kubernetes cluster connection..."
    
    # Run kubectl cluster-info with a timeout
    $job = Start-Job -ScriptBlock { 
        $result = kubectl cluster-info 2>&1
        return @{
            Output = $result
            ExitCode = $LASTEXITCODE
        }
    }
    
    $completed = Wait-Job -Job $job -Timeout 20
    
    if (-not $completed) {
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        Write-Error "Cannot connect to Kubernetes cluster (timeout after 20 seconds)"
        Write-Error "Please ensure you have a k3d cluster running:"
        Write-Error "  k3d cluster create drasi-tutorial -p '8123:80@loadbalancer'"
        Write-Error ""
        Write-Error "Or check your kubectl context:"
        Write-Error "  kubectl config current-context"
        exit 1
    }
    
    # Get the job result
    $jobResult = Receive-Job -Job $job
    Remove-Job -Job $job
    
    # Check if kubectl command succeeded
    if ($jobResult.ExitCode -ne 0) {
        Write-Error "No Kubernetes cluster found or connection failed"
        Write-Error "Please create a k3d cluster first:"
        Write-Error "  k3d cluster create drasi-tutorial -p '8123:80@loadbalancer'"
        exit 1
    }
    
    Write-Success "cluster: OK"
    
    # Check drasi CLI
    if (-not (Test-Command "drasi")) {
        Write-Error "drasi CLI not found. Install from https://drasi.io/reference/command-line-interface/#get-the-drasi-cli"
        exit 1
    }
    Write-Success "drasi: OK"
}

function Initialize-Drasi {
    Write-Info "Checking Drasi installation..."
    
    # Check if drasi-system namespace exists
    $namespaceExists = kubectl get namespace drasi-system 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Drasi is already initialized"
    }
    else {
        Write-Warning "Drasi is not initialized"
        $response = Read-Host "Initialize Drasi now? (y/n)"
        
        if ($response -ne 'y') {
            Write-Warning "Skipping Drasi initialization. You can run 'drasi init' manually later."
            Write-Warning "Note: Drasi resources deployment will be skipped."
            return $false
        }
        
        Write-Info "Initializing Drasi..."
        
        # Configure drasi environment
        drasi env kube
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to configure Drasi environment"
            exit 1
        }
        
        # Try to initialize Drasi (up to 3 attempts)
        $maxAttempts = 3
        for ($i = 1; $i -le $maxAttempts; $i++) {
            Write-Info "Initialization attempt $i of $maxAttempts..."
            
            drasi init
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Drasi initialized successfully"
                Start-Sleep -Seconds 10  # Give resources time to create
                break
            }
            
            if ($i -lt $maxAttempts) {
                Write-Warning "Initialization failed, cleaning up and retrying..."
                drasi uninstall -y 2>&1 | Out-Null
                Start-Sleep -Seconds 5
            }
            else {
                Write-Error "Failed to initialize Drasi after $maxAttempts attempts"
                exit 1
            }
        }
    }
    
    # Verify Drasi is working
    Write-Info "Verifying Drasi installation..."
    $null = drasi list source 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Drasi installation failed. Please check logs."
        exit 1
    }
    Write-Success "Drasi is ready"
    return $true
}

function Deploy-Databases {
    Write-Info "Deploying databases..."
    
    Set-Location $TutorialDir
    
    # Deploy PostgreSQL
    Write-Info "Deploying PostgreSQL database..."
    kubectl apply -f retail-ops/k8s/postgres-database.yaml
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy PostgreSQL"
        exit 1
    }
    
    # Deploy MySQL
    Write-Info "Deploying MySQL database..."
    kubectl apply -f physical-ops/k8s/mysql-database.yaml
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy MySQL"
        exit 1
    }
    
    # Wait for databases to be ready
    Write-Info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s
    if ($LASTEXITCODE -ne 0) {
        Write-Error "PostgreSQL failed to start"
        exit 1
    }
    Write-Success "PostgreSQL: Ready"
    
    Write-Info "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
    if ($LASTEXITCODE -ne 0) {
        Write-Error "MySQL failed to start"
        exit 1
    }
    Write-Success "MySQL: Ready"
}

function Deploy-Applications {
    Write-Info "Deploying applications..."
    
    Set-Location $TutorialDir
    
    # Deploy all applications
    kubectl apply -f delivery-dashboard/k8s/deployment.yaml
    kubectl apply -f delay-dashboard/k8s/deployment.yaml
    kubectl apply -f demo/k8s/deployment.yaml
    kubectl apply -f physical-ops/k8s/deployment.yaml
    kubectl apply -f retail-ops/k8s/deployment.yaml
    
    # Wait for deployments to be ready
    Write-Info "Waiting for applications to be ready..."
    
    $apps = @("delivery-dashboard", "delay-dashboard", "demo", "physical-ops", "retail-ops")
    foreach ($app in $apps) {
        kubectl wait --for=condition=available deployment/$app --timeout=300s
        if ($LASTEXITCODE -eq 0) {
            Write-Success "${app}: Ready"
        }
        else {
            Write-Error "${app}: Failed to start"
            exit 1
        }
    }
}

function Setup-Ingress {
    Write-Info "Checking for Traefik v2.x ingress controller..."
    
    # Check if Traefik CRDs exist (v2.x uses traefik.containo.us)
    $null = kubectl get crd ingressroutes.traefik.containo.us 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Traefik v2.x not found. Skipping ingress setup."
        return $false
    }
    
    Write-Info "Attempting to deploy ingress routes..."
    Set-Location $TutorialDir
    
    # Try to deploy ingress routes
    $ingressFailed = $false
    kubectl apply -f delivery-dashboard/k8s/ingress.yaml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $ingressFailed = $true }
    
    kubectl apply -f delay-dashboard/k8s/ingress.yaml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $ingressFailed = $true }
    
    kubectl apply -f demo/k8s/ingress.yaml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $ingressFailed = $true }
    
    kubectl apply -f physical-ops/k8s/ingress.yaml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $ingressFailed = $true }
    
    kubectl apply -f retail-ops/k8s/ingress.yaml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $ingressFailed = $true }
    
    if (-not $ingressFailed) {
        Write-Success "Ingress routes configured"
        return $true
    }
    else {
        Write-Warning "Some ingress routes failed to deploy"
        return $false
    }
}

function Show-AccessInstructions($useIngress) {
    Write-Host ""
    Write-Success "Setup complete!"
    Write-Host ""
    
    if ($useIngress) {
        Write-Info "Access the applications at:"
        Write-Host "  - Demo (All Apps):    http://localhost:8123/"
        Write-Host "  - Physical Ops:       http://localhost:8123/physical-ops"
        Write-Host "  - Retail Ops:         http://localhost:8123/retail-ops"
        Write-Host "  - Delivery Dashboard: http://localhost:8123/delivery-dashboard"
        Write-Host "  - Delay Dashboard:    http://localhost:8123/delay-dashboard"
        Write-Host "  - Physical Ops API:   http://localhost:8123/physical-ops/docs"
        Write-Host "  - Retail Ops API:     http://localhost:8123/retail-ops/docs"
        Write-Host ""
        Write-Info "Note: This assumes your k3d cluster was created with port mapping 8123:80"
    }
    else {
        Write-Info "Ingress not configured. Use one of these options:"
        Write-Host ""
        Write-Host "Option 1: Configure ingress manually (if you have Traefik or another ingress controller)"
        Write-Host ""
        Write-Host "Option 2: Use port-forwarding to access the applications:"
        Write-Host "  - Delivery Dashboard: kubectl port-forward svc/delivery-dashboard 3000:3000"
        Write-Host "  - Delay Dashboard:    kubectl port-forward svc/delay-dashboard 3001:3000"
        Write-Host "  - Demo Portal:        kubectl port-forward svc/demo 3002:3000"
        Write-Host "  - Physical Ops:       kubectl port-forward svc/physical-ops 8003:8003"
        Write-Host "  - Retail Ops:         kubectl port-forward svc/retail-ops 8004:8004"
    }
    
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Deploy Drasi resources: cd tutorial/curbside-pickup/drasi"
    Write-Host "  2. Apply sources, queries, and reactions"
    Write-Host ""
}

# Main execution
Show-Header
Test-Prerequisites

# Try to initialize Drasi but continue even if user declines
$drasiInitialized = Initialize-Drasi

Deploy-Databases
Deploy-Applications
$useIngress = Setup-Ingress
Show-AccessInstructions $useIngress

# Additional warning if Drasi wasn't initialized
if (-not $drasiInitialized) {
    Write-Host ""
    Write-Warning "Remember: Drasi was not initialized. The tutorial applications are deployed,"
    Write-Warning "but you'll need to run 'drasi init' manually before deploying Drasi resources."
}