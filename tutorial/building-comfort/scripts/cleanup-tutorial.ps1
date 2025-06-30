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

# Cleanup script for Building Comfort tutorial (Windows PowerShell version)
#Requires -Version 5.1

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Navigate up from scripts -> building-comfort -> tutorial -> learning
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))

# Source shared functions
. "$ProjectRoot\scripts\setup-functions.ps1"

# Check for Administrator privileges (may be needed for Drasi uninstall)
if (-not (Test-Administrator)) {
    Write-Warning "This script may require Administrator privileges for some operations."
    Write-Info "If any operations fail, please run PowerShell as Administrator."
}

# Display header
Clear-Host
Write-Host ""
Write-Host "+========================================+" -ForegroundColor Yellow
Write-Host "|     Building Comfort Cleanup           |" -ForegroundColor Yellow
Write-Host "+========================================+" -ForegroundColor Yellow
Write-Host ""

Write-Warning "This script will clean up the Building Comfort tutorial resources."
Write-Host ""

# Step 1: Delete tutorial resources
Write-Info "Step 1: Delete Building Comfort tutorial resources"
if (Read-UserChoice "Delete all tutorial Kubernetes resources (deployments, services, etc.)?") {
    Write-Info "Deleting tutorial resources..."
    
    # Delete application deployments and services
    Remove-K8sResourcesByLabel -Label "app=building-comfort"
    
    # Delete specific resources
    $resources = @(
        @{Type="deployment"; Name="postgres"},
        @{Type="deployment"; Name="control-panel"},
        @{Type="deployment"; Name="dashboard"},
        @{Type="deployment"; Name="demo"},
        @{Type="service"; Name="postgres"},
        @{Type="service"; Name="control-panel"},
        @{Type="service"; Name="dashboard"},
        @{Type="service"; Name="demo"},
        @{Type="configmap"; Name="postgres-init"},
        @{Type="ingressroute"; Name="control-panel"},
        @{Type="ingressroute"; Name="dashboard"},
        @{Type="ingressroute"; Name="demo"},
        @{Type="middleware"; Name="control-panel-strip-prefix"},
        @{Type="middleware"; Name="dashboard-strip-prefix"}
    )
    
    foreach ($resource in $resources) {
        Remove-K8sResources -ResourceType $resource.Type -ResourceName $resource.Name
    }
    
    Write-Success "Tutorial resources deleted"
}
else {
    Write-Info "Skipping tutorial resource deletion"
}

Write-Host ""

# Step 2: Uninstall Drasi (optional)
Write-Info "Step 2: Uninstall Drasi (optional)"
Write-Warning "This will remove Drasi from your cluster. Other tutorials using Drasi will be affected."

if (Read-UserChoice "Uninstall Drasi from the cluster?") {
    Write-Info "Checking if Drasi is installed..."
    
    if (Test-K8sResource "namespace" "drasi-system") {
        Write-Info "Uninstalling Drasi..."
        try {
            drasi uninstall -y 2>$null
            Write-Success "Drasi uninstalled successfully"
        }
        catch {
            Write-Error "Failed to uninstall Drasi: $_"
            Write-Info "You may need to run 'drasi uninstall -y' manually"
        }
    }
    else {
        Write-Info "Drasi is not installed"
    }
}
else {
    Write-Info "Skipping Drasi uninstallation"
}

Write-Host ""

# Step 3: Delete k3d cluster (optional)
Write-Info "Step 3: Delete k3d cluster (optional)"
Write-Warning "This will delete the entire k3d cluster and all resources within it."

if (Test-CommandExists "k3d") {
    # Check for k3d clusters
    try {
        $clusters = k3d cluster list -o json 2>$null | ConvertFrom-Json
        $clusterNames = $clusters | ForEach-Object { $_.name }
    }
    catch {
        $clusterNames = @()
    }
    
    if ($clusterNames.Count -gt 0) {
        Write-Info "Found k3d clusters: $($clusterNames -join ', ')"
        
        # Check if drasi-tutorial cluster exists
        if ($clusterNames -contains "drasi-tutorial") {
            if (Read-UserChoice "Delete the 'drasi-tutorial' k3d cluster?") {
                Write-Info "Deleting k3d cluster 'drasi-tutorial'..."
                k3d cluster delete drasi-tutorial
                Write-Success "k3d cluster deleted successfully"
            }
            else {
                Write-Info "Keeping k3d cluster"
            }
        }
        else {
            Write-Info "No 'drasi-tutorial' cluster found"
            
            # Offer to delete other clusters
            if ($clusterNames.Count -eq 1) {
                $clusterName = $clusterNames[0]
                if (Read-UserChoice "Delete the '$clusterName' k3d cluster?") {
                    Write-Info "Deleting k3d cluster '$clusterName'..."
                    k3d cluster delete $clusterName
                    Write-Success "k3d cluster deleted successfully"
                }
            }
            elseif ($clusterNames.Count -gt 1) {
                Write-Info "Multiple clusters found. Please use 'k3d cluster delete <name>' to delete specific clusters."
            }
        }
    }
    else {
        Write-Info "No k3d clusters found"
    }
}
else {
    Write-Info "k3d is not installed"
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Success "Cleanup complete!"
Write-Host ""
Write-Host "Thank you for trying the Building Comfort tutorial!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Learn more about Drasi:" -ForegroundColor Yellow
Write-Host "   Documentation: https://drasi.io/docs" -ForegroundColor Gray
Write-Host "   GitHub: https://github.com/drasi-project" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""