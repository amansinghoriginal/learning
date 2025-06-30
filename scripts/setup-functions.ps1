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

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check and require Administrator privileges
function Require-Administrator {
    if (-not (Test-Administrator)) {
        Write-Error "This script requires Administrator privileges."
        Write-Host ""
        Write-Host "Please run PowerShell as Administrator:" -ForegroundColor Yellow
        Write-Host "  1. Right-click on PowerShell" -ForegroundColor Gray
        Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
        Write-Host "  3. Navigate to the script directory and run again" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or use this command from an elevated PowerShell:" -ForegroundColor Yellow
        Write-Host "  cd '$PWD'" -ForegroundColor Cyan
        Write-Host "  $($MyInvocation.MyCommand.Name)" -ForegroundColor Cyan
        exit 1
    }
    Write-Success "Running with Administrator privileges"
}

# Output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
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
    Write-Host "`n[MENU] Select deployment mode:" -ForegroundColor Cyan
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
        Write-Info "kubectl is required to interact with Kubernetes clusters"
        
        # Offer to install using package managers (kubectl only)
        if (Test-CommandExists "winget") {
            if (Read-UserChoice "Would you like to install kubectl using winget?") {
                Write-Info "Installing kubectl with winget..."
                try {
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
                catch {
                    Write-Error "Failed to install kubectl with winget: $_"
                    exit 1
                }
            }
            else {
                Write-Info "kubectl installation declined"
                Write-Info "Please install kubectl manually from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
                exit 1
            }
        }
        elseif (Test-CommandExists "choco") {
            if (Read-UserChoice "Would you like to install kubectl using Chocolatey?") {
                Write-Info "Installing kubectl with Chocolatey..."
                try {
                    choco install kubernetes-cli -y
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
                catch {
                    Write-Error "Failed to install kubectl with Chocolatey: $_"
                    exit 1
                }
            }
            else {
                Write-Info "kubectl installation declined"
                Write-Info "Please install kubectl manually from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
                exit 1
            }
        }
        else {
            Write-Error "No package manager found (winget or Chocolatey)"
            Write-Info "Please install kubectl manually from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
            Write-Info "Or install winget from: https://github.com/microsoft/winget-cli/releases"
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
            
            # Use the official PowerShell installer
            try {
                # Download the installer script first to avoid variable conflicts
                $installerScript = Invoke-WebRequest -useb "https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.ps1"
                
                # Create a new scope to avoid variable conflicts with strict mode
                & {
                    # Temporarily disable strict mode for the installer
                    Set-StrictMode -Off
                    $installerScript.Content | Invoke-Expression
                }
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Sometimes we need to restart the shell, but let's check first
                Start-Sleep -Seconds 2
                
                if (Test-CommandExists "drasi") {
                    Write-Success "Drasi CLI installed successfully"
                }
                else {
                    Write-Warning "Drasi CLI installed but not found in PATH"
                    Write-Info "You may need to restart your PowerShell session"
                    Write-Info "After restarting, run this script again"
                    exit 0
                }
            }
            catch {
                Write-Error "Failed to install Drasi CLI: $_"
                Write-Info "Try running these commands manually in a new PowerShell window:"
                Write-Host 'Set-StrictMode -Off' -ForegroundColor Yellow
                Write-Host 'iwr -useb "https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.ps1" | iex' -ForegroundColor Yellow
                Write-Info "Or download and run the installer from: https://github.com/drasi-project/drasi-platform/releases"
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
        
        if (Read-UserChoice "Would you like to install k3d $RequiredVersion?") {
            Write-Info "Installing k3d $RequiredVersion..."
            
            # Download and install k3d directly
            $k3dUrl = "https://github.com/k3d-io/k3d/releases/download/$RequiredVersion/k3d-windows-amd64.exe"
            $targetPath = "C:\Tools\k3d\k3d.exe"
            
            try {
                # Create folder if it doesn't exist
                New-Item -ItemType Directory -Force -Path "C:\Tools\k3d" | Out-Null
                
                # Download k3d
                Write-Info "Downloading k3d from GitHub..."
                Invoke-WebRequest -Uri $k3dUrl -OutFile $targetPath -UseBasicParsing
                
                # Add to PATH if not already there
                $envPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
                if ($envPath -notlike "*C:\Tools\k3d*") {
                    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;C:\Tools\k3d", [System.EnvironmentVariableTarget]::Machine)
                    Write-Info "Added C:\Tools\k3d to system PATH"
                    
                    # Also update current session PATH
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                }
                
                # Verify installation
                & $targetPath version | Out-Null
                Write-Success "k3d $RequiredVersion installed successfully"
                return $true
            }
            catch {
                Write-Error "Failed to install k3d: $_"
                Write-Info "Please install k3d manually from: https://k3d.io/stable/#installation"
                return $false
            }
        }
        else {
            Write-Error "k3d is required for this tutorial"
            Write-Info "Please install k3d manually from: https://k3d.io/stable/#installation"
            return $false
        }
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
    $requiredCRDs = @("middlewares.traefik.containo.us", "ingressroutes.traefik.containo.us")
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
            Write-Info "Note: k3d sometimes takes longer to install Traefik. You can continue with port-forwarding."
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
            if (Test-K8sResource "crd" "ingressroutes.traefik.containo.us" "all-namespaces") {
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
                            drasi uninstall -y 2>$null
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
    Write-Host "+========================================+" -ForegroundColor Cyan
    Write-Host "|         Drasi Tutorial Setup           |" -ForegroundColor Cyan
    Write-Host "|                                        |" -ForegroundColor Cyan
    Write-Host ("|  " + $TutorialName.PadRight(36) + "  |") -ForegroundColor Cyan
    Write-Host "+========================================+" -ForegroundColor Cyan
    Write-Host ""
}

# Show completion message
function Show-Completion {
    param(
        [string]$AccessUrl,
        [string]$TutorialName
    )
    
    Write-Host ""
    Write-Host "+========================================+" -ForegroundColor Green
    Write-Host "|        Setup Complete!                 |" -ForegroundColor Green
    Write-Host "+========================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Tutorial: $TutorialName" -ForegroundColor Cyan
    Write-Host "[INFO] Access URL: $AccessUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[NEXT] Steps:" -ForegroundColor Yellow
    Write-Host "   1. Navigate to the drasi folder: cd drasi" -ForegroundColor White
    Write-Host "   2. Apply Drasi sources and queries as shown in the tutorial" -ForegroundColor White
    Write-Host "   3. Explore the demo application at $AccessUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "[TIP] Keep this terminal open to see any setup logs" -ForegroundColor Gray
    Write-Host ""
}