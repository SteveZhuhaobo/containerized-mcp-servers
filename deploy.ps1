# PowerShell deployment script for MCP Servers
# This script helps you rebuild and push Docker images when code is updated

param(
    [string]$Action = "build",
    [string]$Server = "all",
    [string]$Version = "latest",
    [switch]$Push = $false,
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "MCP Servers Deployment Script" -ForegroundColor Green
    Write-Host "Usage: .\deploy.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Action <build|push|all>    Action to perform (default: build)"
    Write-Host "  -Server <all|snowflake|databricks|sqlserver>  Which server to deploy (default: all)"
    Write-Host "  -Version <version>          Version tag (default: latest)"
    Write-Host "  -Push                       Push images to registry after building"
    Write-Host "  -Help                       Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1                                    # Build all servers"
    Write-Host "  .\deploy.ps1 -Server sqlserver                  # Build only SQL Server MCP"
    Write-Host "  .\deploy.ps1 -Action all -Push                  # Build and push all servers"
    Write-Host "  .\deploy.ps1 -Server snowflake -Version v1.0.0 -Push  # Build and push Snowflake MCP with version tag"
}

function Test-Docker {
    try {
        docker --version | Out-Null
        return $true
    }
    catch {
        Write-Host "❌ Docker is not installed or not running" -ForegroundColor Red
        return $false
    }
}

function Build-Server {
    param(
        [string]$ServerName,
        [string]$Version
    )
    
    $ServerPath = "$ServerName-mcp"
    $ImageName = "ghcr.io/$env:GITHUB_USERNAME/$ServerName-mcp"
    
    if (-not $env:GITHUB_USERNAME) {
        Write-Host "⚠️  GITHUB_USERNAME environment variable not set. Using 'your-username' as placeholder." -ForegroundColor Yellow
        $ImageName = "ghcr.io/your-username/$ServerName-mcp"
    }
    
    Write-Host "🔨 Building $ServerName MCP Server..." -ForegroundColor Blue
    Write-Host "   Path: $ServerPath" -ForegroundColor Gray
    Write-Host "   Image: $ImageName:$Version" -ForegroundColor Gray
    
    if (-not (Test-Path $ServerPath)) {
        Write-Host "❌ Server directory not found: $ServerPath" -ForegroundColor Red
        return $false
    }
    
    try {
        docker build -t "$ImageName:$Version" -t "$ImageName:latest" $ServerPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully built $ServerName MCP Server" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to build $ServerName MCP Server" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error building $ServerName MCP Server: $_" -ForegroundColor Red
        return $false
    }
}

function Push-Server {
    param(
        [string]$ServerName,
        [string]$Version
    )
    
    $ImageName = "ghcr.io/$env:GITHUB_USERNAME/$ServerName-mcp"
    
    if (-not $env:GITHUB_USERNAME) {
        $ImageName = "ghcr.io/your-username/$ServerName-mcp"
    }
    
    Write-Host "📤 Pushing $ServerName MCP Server..." -ForegroundColor Blue
    
    try {
        docker push "$ImageName:$Version"
        docker push "$ImageName:latest"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully pushed $ServerName MCP Server" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to push $ServerName MCP Server" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error pushing $ServerName MCP Server: $_" -ForegroundColor Red
        return $false
    }
}

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Host "🚀 MCP Servers Deployment Script" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    
    if (-not (Test-Docker)) {
        return
    }
    
    $Servers = @()
    if ($Server -eq "all") {
        $Servers = @("snowflake", "databricks", "sqlserver")
    } else {
        $Servers = @($Server)
    }
    
    $BuildResults = @{}
    $PushResults = @{}
    
    # Build phase
    if ($Action -eq "build" -or $Action -eq "all") {
        Write-Host "🔨 Building Docker images..." -ForegroundColor Cyan
        foreach ($srv in $Servers) {
            $BuildResults[$srv] = Build-Server -ServerName $srv -Version $Version
        }
    }
    
    # Push phase
    if (($Action -eq "push" -or $Action -eq "all" -or $Push) -and ($BuildResults.Values -contains $true -or $Action -eq "push")) {
        Write-Host "📤 Pushing Docker images..." -ForegroundColor Cyan
        
        # Check if logged into GitHub Container Registry
        Write-Host "🔐 Checking GitHub Container Registry authentication..." -ForegroundColor Blue
        try {
            docker pull ghcr.io/hello-world 2>$null | Out-Null
        }
        catch {
            Write-Host "⚠️  You may need to login to GitHub Container Registry:" -ForegroundColor Yellow
            Write-Host "   docker login ghcr.io -u YOUR_USERNAME -p YOUR_GITHUB_TOKEN" -ForegroundColor Gray
        }
        
        foreach ($srv in $Servers) {
            if ($Action -eq "push" -or $BuildResults[$srv] -eq $true) {
                $PushResults[$srv] = Push-Server -ServerName $srv -Version $Version
            }
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "📊 Deployment Summary" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    
    foreach ($srv in $Servers) {
        Write-Host "$srv MCP Server:" -ForegroundColor Cyan
        if ($BuildResults.ContainsKey($srv)) {
            $buildStatus = if ($BuildResults[$srv]) { "✅ Built" } else { "❌ Failed" }
            Write-Host "  Build: $buildStatus" -ForegroundColor $(if ($BuildResults[$srv]) { "Green" } else { "Red" })
        }
        if ($PushResults.ContainsKey($srv)) {
            $pushStatus = if ($PushResults[$srv]) { "✅ Pushed" } else { "❌ Failed" }
            Write-Host "  Push:  $pushStatus" -ForegroundColor $(if ($PushResults[$srv]) { "Green" } else { "Red" })
        }
    }
    
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Set GITHUB_USERNAME environment variable: `$env:GITHUB_USERNAME = 'your-username'" -ForegroundColor Gray
    Write-Host "2. Login to GitHub Container Registry: docker login ghcr.io" -ForegroundColor Gray
    Write-Host "3. Push your code to GitHub to trigger automated builds" -ForegroundColor Gray
}

# Run the main function
Main
