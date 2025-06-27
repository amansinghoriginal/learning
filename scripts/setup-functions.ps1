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

# Shared PowerShell functions for tutorial setup scripts
#Requires -Version 5.1

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Output functions
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# User interaction function
function Read-UserChoice {
    param(
        [string]$Prompt,
        [string]$DefaultChoice = "y"
    )
    
    $choice = Read-Host "$Prompt [y/n/q] (default: $DefaultChoice)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $choice = $DefaultChoice
    }
    
    switch ($choice.ToLower()) {
        "y" { return $true }
        "yes" { return $true }
        "s" { Write-Info "Skipping..."; return $false }
        "skip" { Write-Info "Skipping..."; return $false }
        "n" { return $false }
        "no" { return $false }
        "q" { Write-Info "Exiting..."; exit 0 }
        "quit" { Write-Info "Exiting..."; exit 0 }
        default { 
            Write-Warning "Invalid choice. Please enter y, n, s, or q."
            return Read-UserChoice -Prompt $Prompt -DefaultChoice $DefaultChoice
        }
    }
}

# Select deployment mode
function Select-DeploymentMode {
    Write-Host "`n📋 Select deployment mode:" -ForegroundColor Cyan
    Write-Host "  1) Full k3d mode - Set up k3d cluster with Traefik ingress (recommended)" -ForegroundColor White
    Write-Host "  2) Apps-only mode - Deploy to existing Kubernetes cluster (advanced)" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-2] (default: 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $choice = "1"
    }
    
    switch ($choice) {
        "1" { return "k3d" }
        "2" { return "apps-only" }
        default {
            Write-Warning "Invalid choice. Please select 1 or 2."
            return Select-DeploymentMode
        }
    }
}

# Check if command exists
function Test-CommandExists {
    param([string]$Command)
    
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Check kubectl
function Test-Kubectl {
    Write-Info "Checking for kubectl..."
    
    if (Test-CommandExists "kubectl") {
        Write-Success "kubectl is installed"
        
        # Check if we can connect to a cluster
        try {
            $null = kubectl cluster-info 2>&1
            Write-Success "kubectl is connected to a cluster"
        }
        catch {
            Write-Error "kubectl is not connected to any cluster"
            Write-Info "Please ensure kubectl is configured to connect to your Kubernetes cluster"
            exit 1
        }
    }
    else {
        Write-Error "kubectl is not installed"
        Write-Info "Please install kubectl from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
        
        # Offer to install using common Windows package managers
        if (Test-CommandExists "winget") {
            if (Read-UserChoice "Would you like to install kubectl using winget?") {
                Write-Info "Installing kubectl with winget..."
                winget install -e --id Kubernetes.kubectl
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                if (Test-CommandExists "kubectl") {
                    Write-Success "kubectl installed successfully"
                }
                else {
                    Write-Error "Failed to install kubectl"
                    exit 1
                }
            }
            else {
                exit 1
            }
        }
        elseif (Test-CommandExists "choco") {
            if (Read-UserChoice "Would you like to install kubectl using Chocolatey?") {
                Write-Info "Installing kubectl with Chocolatey..."
                choco install kubernetes-cli -y
                if (Test-CommandExists "kubectl") {
                    Write-Success "kubectl installed successfully"
                }
                else {
                    Write-Error "Failed to install kubectl"
                    exit 1
                }
            }
            else {
                exit 1
            }
        }
        elseif (Test-CommandExists "scoop") {
            if (Read-UserChoice "Would you like to install kubectl using Scoop?") {
                Write-Info "Installing kubectl with Scoop..."
                scoop install kubectl
                if (Test-CommandExists "kubectl") {
                    Write-Success "kubectl installed successfully"
                }
                else {
                    Write-Error "Failed to install kubectl"
                    exit 1
                }
            }
            else {
                exit 1
            }
        }
        else {
            exit 1
        }
    }
}

# Check if Drasi CLI is installed
function Test-DrasiCLI {
    Write-Info "Checking for Drasi CLI..."
    
    if (Test-CommandExists "drasi") {
        Write-Success "Drasi CLI is installed"
        $version = drasi version 2>$null
        if ($version) {
            Write-Info "Drasi CLI version: $version"
        }
    }
    else {
        Write-Warning "Drasi CLI is not installed"
        
        if (Read-UserChoice "Would you like to install Drasi CLI?") {
            Write-Info "Installing Drasi CLI..."
            
            # Download and run the Windows installer
            try {
                $installerUrl = "https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.ps1"
                $installerPath = "$env:TEMP\install-drasi-cli.ps1"
                
                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                & $installerPath
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                if (Test-CommandExists "drasi") {
                    Write-Success "Drasi CLI installed successfully"
                }
                else {
                    Write-Error "Failed to install Drasi CLI"
                    Write-Info "Please install manually from: https://drasi.io/how-to-guides/installation"
                    exit 1
                }
            }
            catch {
                Write-Error "Failed to download Drasi CLI installer: $_"
                exit 1
            }
        }
        else {
            Write-Info "Skipping Drasi CLI installation"
            Write-Warning "You will need to install Drasi manually later"
        }
    }
}

# Check and install k3d
function Test-K3d {
    param([string]$RequiredVersion = "v5.6.0")
    
    Write-Info "Checking for k3d..."
    
    if (Test-CommandExists "k3d") {
        $installedVersion = (k3d version 2>$null | Select-String "k3d version").ToString() -replace "k3d version ", ""
        Write-Success "k3d is installed (version: $installedVersion)"
        
        # Check if it's the expected version
        if ($installedVersion -notlike "*$RequiredVersion*") {
            Write-Warning "Note: This tutorial was tested with k3d $RequiredVersion"
            Write-Warning "You have $installedVersion installed. Some features may work differently."
        }
        return $true
    }
    else {
        Write-Warning "k3d is not installed"
        Write-Info "k3d is required to create local Kubernetes clusters"
        
        # Try to install k3d
        if (Test-CommandExists "winget") {
            if (Read-UserChoice "Would you like to install k3d using winget?") {
                Write-Info "Installing k3d with winget..."
                winget install -e --id k3d.k3d
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                if (Test-CommandExists "k3d") {
                    Write-Success "k3d installed successfully"
                    return $true
                }
            }
        }
        elseif (Test-CommandExists "choco") {
            if (Read-UserChoice "Would you like to install k3d using Chocolatey?") {
                Write-Info "Installing k3d with Chocolatey..."
                choco install k3d -y
                if (Test-CommandExists "k3d") {
                    Write-Success "k3d installed successfully"
                    return $true
                }
            }
        }
        elseif (Test-CommandExists "scoop") {
            if (Read-UserChoice "Would you like to install k3d using Scoop?") {
                Write-Info "Installing k3d with Scoop..."
                scoop install k3d
                if (Test-CommandExists "k3d") {
                    Write-Success "k3d installed successfully"
                    return $true
                }
            }
        }
        
        # If all installation methods fail or are declined
        Write-Error "k3d installation failed or was declined"
        Write-Info "Please install k3d manually from: https://k3d.io/stable/#installation"
        Write-Info "Or use the following PowerShell command:"
        Write-Host "Invoke-WebRequest -Uri 'https://github.com/k3d-io/k3d/releases/download/$RequiredVersion/k3d-windows-amd64.exe' -OutFile 'k3d.exe'" -ForegroundColor Yellow
        return $false
    }
}

# Check if Traefik is installed in k3d
function Test-Traefik {
    Write-Info "Checking for Traefik in the cluster..."
    
    # First check if Traefik helm release exists and is deployed
    try {
        $helmStatus = kubectl get configmap -n kube-system -o json 2>$null | ConvertFrom-Json
        $traefikHelmRelease = $helmStatus.items | Where-Object { 
            $_.metadata.name -like "*traefik*" -and 
            $_.metadata.labels."name" -eq "traefik" -and
            $_.metadata.labels."owner" -eq "helm"
        }
        
        if ($traefikHelmRelease) {
            Write-Info "Found Traefik Helm release, checking status..."
            
            # Check if Traefik job completed
            try {
                $jobs = kubectl get jobs -n kube-system --selector="app.kubernetes.io/name=traefik" -o json 2>$null | ConvertFrom-Json
                $installJob = $jobs.items | Where-Object { $_.metadata.name -like "*traefik*" }
                
                if ($installJob -and $installJob.status.succeeded -eq 1) {
                    Write-Success "Traefik Helm job completed successfully"
                }
                else {
                    Write-Info "Waiting for Traefik Helm job to complete..."
                    kubectl wait --for=condition=complete job -l app.kubernetes.io/name=traefik -n kube-system --timeout=120s 2>$null
                }
            }
            catch {
                Write-Warning "Could not verify Traefik job status"
            }
        }
    }
    catch {
        Write-Info "No Helm-managed Traefik found (this is normal for non-k3d clusters)"
    }
    
    # Check for Traefik CRDs
    Write-Info "Checking for Traefik CRDs..."
    $requiredCRDs = @("middlewares.traefik.io", "ingressroutes.traefik.io")
    $missingCRDs = @()
    
    foreach ($crd in $requiredCRDs) {
        try {
            $null = kubectl get crd $crd 2>&1
            Write-Success "Found CRD: $crd"
        }
        catch {
            $missingCRDs += $crd
        }
    }
    
    if ($missingCRDs.Count -gt 0) {
        Write-Warning "Missing Traefik CRDs: $($missingCRDs -join ', ')"
        Write-Info "These are required for ingress routing"
        
        # Try to wait a bit more
        Write-Info "Waiting for CRDs to be created..."
        Start-Sleep -Seconds 10
        
        # Check again
        $stillMissing = @()
        foreach ($crd in $missingCRDs) {
            try {
                $null = kubectl get crd $crd 2>&1
            }
            catch {
                $stillMissing += $crd
            }
        }
        
        if ($stillMissing.Count -gt 0) {
            Write-Warning "Still missing CRDs: $($stillMissing -join ', ')"
            Write-Warning "Traefik may not be properly installed. Ingress features will not work."
            return $false
        }
    }
    
    Write-Success "Traefik is properly configured"
    return $true
}

# Check if k8s resource exists
function Test-K8sResource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Namespace = "default"
    )
    
    try {
        if ($Namespace -eq "all-namespaces") {
            $null = kubectl get $ResourceType $ResourceName --all-namespaces 2>&1
        }
        else {
            $null = kubectl get $ResourceType $ResourceName -n $Namespace 2>&1
        }
        return $true
    }
    catch {
        return $false
    }
}

# Wait for deployment to be ready
function Wait-ForDeployment {
    param(
        [string]$DeploymentName,
        [string]$Namespace = "default",
        [int]$Timeout = 300
    )
    
    Write-Info "Waiting for deployment '$DeploymentName' to be ready..."
    
    try {
        kubectl wait --for=condition=available --timeout="${Timeout}s" deployment/$DeploymentName -n $Namespace 2>$null
        Write-Success "Deployment '$DeploymentName' is ready"
    }
    catch {
        Write-Warning "Deployment '$DeploymentName' is not ready after ${Timeout}s"
    }
}

# Deploy app with optional ingress
function Deploy-App {
    param(
        [string]$AppName,
        [string]$Directory,
        [string]$DeployIngress = "true",
        [string]$Namespace = "default"
    )
    
    Write-Info "Deploying $AppName..."
    
    # Deploy the deployment
    $deploymentFile = Join-Path $Directory "deployment.yaml"
    if (Test-Path $deploymentFile) {
        kubectl apply -f $deploymentFile -n $Namespace
    }
    else {
        Write-Error "Deployment file not found: $deploymentFile"
        return
    }
    
    # Deploy ingress if requested and available
    if ($DeployIngress -eq "true") {
        $ingressFile = Join-Path $Directory "ingress.yaml"
        if (Test-Path $ingressFile) {
            if (Test-K8sResource "crd" "ingressroutes.traefik.io" "all-namespaces") {
                kubectl apply -f $ingressFile -n $Namespace
                Write-Success "$AppName deployed with ingress"
            }
            else {
                Write-Warning "Skipping ingress for $AppName (Traefik CRDs not available)"
            }
        }
    }
    else {
        Write-Info "Skipping ingress deployment for $AppName"
    }
}

# Initialize Drasi with retry
function Initialize-Drasi {
    param([int]$MaxAttempts = 3)
    
    Write-Info "Initializing Drasi..."
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Info "Initialization attempt $attempt of $MaxAttempts..."
        
        try {
            # Check if Drasi is already initialized
            if (Test-K8sResource "namespace" "drasi-system") {
                Write-Info "Drasi namespace already exists, checking status..."
                
                # Check if core components are running
                $coreComponents = @("drasi-platform")
                $allReady = $true
                
                foreach ($component in $coreComponents) {
                    if (-not (Test-K8sResource "deployment" $component "drasi-system")) {
                        $allReady = $false
                        break
                    }
                }
                
                if ($allReady) {
                    Write-Success "Drasi is already initialized and running"
                    return
                }
                else {
                    Write-Warning "Drasi namespace exists but components are missing"
                    if ($attempt -lt $MaxAttempts) {
                        if (Read-UserChoice "Would you like to uninstall and retry?") {
                            Write-Info "Uninstalling existing Drasi installation..."
                            drasi uninstall 2>$null
                            Start-Sleep -Seconds 5
                        }
                        else {
                            Write-Error "Drasi initialization incomplete"
                            exit 1
                        }
                    }
                }
            }
            
            # Run drasi init
            drasi init
            
            # Wait a bit for resources to be created
            Start-Sleep -Seconds 10
            
            # Verify initialization
            if (Test-K8sResource "namespace" "drasi-system") {
                Write-Success "Drasi initialized successfully"
                return
            }
            else {
                throw "Drasi namespace not created"
            }
        }
        catch {
            Write-Error "Drasi initialization failed: $_"
            
            if ($attempt -lt $MaxAttempts) {
                Write-Info "Retrying in 10 seconds..."
                Start-Sleep -Seconds 10
            }
            else {
                Write-Error "Failed to initialize Drasi after $MaxAttempts attempts"
                Write-Info "Please check the logs and try running 'drasi init' manually"
                exit 1
            }
        }
    }
}

# Delete Kubernetes resources safely
function Remove-K8sResources {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Namespace = "default"
    )
    
    if (Test-K8sResource $ResourceType $ResourceName $Namespace) {
        Write-Info "Deleting $ResourceType/$ResourceName in namespace $Namespace..."
        kubectl delete $ResourceType $ResourceName -n $Namespace --ignore-not-found=true 2>$null
    }
}

# Delete resources by label
function Remove-K8sResourcesByLabel {
    param(
        [string]$Label,
        [string]$Namespace = "default"
    )
    
    Write-Info "Deleting resources with label $Label in namespace $Namespace..."
    
    $resourceTypes = @("deployment", "service", "configmap", "ingress", "ingressroute")
    
    foreach ($type in $resourceTypes) {
        try {
            $resources = kubectl get $type -l $Label -n $Namespace -o json 2>$null | ConvertFrom-Json
            if ($resources.items.Count -gt 0) {
                kubectl delete $type -l $Label -n $Namespace 2>$null
                Write-Success "Deleted $($resources.items.Count) $type(s)"
            }
        }
        catch {
            # Resource type might not exist, that's ok
        }
    }
}

# Show setup header
function Show-Header {
    param([string]$TutorialName)
    
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Drasi Tutorial Setup           ║" -ForegroundColor Cyan
    Write-Host "║                                        ║" -ForegroundColor Cyan
    Write-Host ("║  " + $TutorialName.PadRight(36) + "  ║") -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Show completion message
function Show-Completion {
    param(
        [string]$AccessUrl,
        [string]$TutorialName
    )
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║        Setup Complete! 🎉              ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Tutorial: $TutorialName" -ForegroundColor Cyan
    Write-Host "🌐 Access URL: $AccessUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📚 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Navigate to the drasi folder: cd drasi" -ForegroundColor White
    Write-Host "   2. Apply Drasi sources and queries as shown in the tutorial" -ForegroundColor White
    Write-Host "   3. Explore the demo application at $AccessUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Tip: Keep this terminal open to see any setup logs" -ForegroundColor Gray
    Write-Host ""
}