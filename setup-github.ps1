# GitHub Repository Setup Script for MCP Servers
# This script helps you set up the GitHub repository and configure automated Docker builds

param(
    [string]$RepoName = "containerized-mcp-servers",
    [string]$GitHubUsername = "",
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "GitHub Repository Setup Script" -ForegroundColor Green
    Write-Host "Usage: .\setup-github.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -RepoName <name>           Repository name (default: containerized-mcp-servers)"
    Write-Host "  -GitHubUsername <username> Your GitHub username"
    Write-Host "  -Help                      Show this help message"
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "1. Create a new repository on GitHub: https://github.com/new"
    Write-Host "2. Name it: $RepoName"
    Write-Host "3. Make it public (for GitHub Container Registry access)"
    Write-Host "4. Don't initialize with README (we have our own files)"
}

function Test-Git {
    try {
        git --version | Out-Null
        return $true
    }
    catch {
        Write-Host "❌ Git is not installed" -ForegroundColor Red
        Write-Host "Please install Git from: https://git-scm.com/download/windows" -ForegroundColor Yellow
        return $false
    }
}

function Initialize-Repository {
    param([string]$Username, [string]$RepoName)
    
    Write-Host "🔧 Initializing Git repository..." -ForegroundColor Blue
    
    # Initialize git if not already done
    if (-not (Test-Path ".git")) {
        git init
        Write-Host "✅ Git repository initialized" -ForegroundColor Green
    }
    
    # Add all files
    Write-Host "📁 Adding files to repository..." -ForegroundColor Blue
    git add .
    
    # Create initial commit
    Write-Host "💾 Creating initial commit..." -ForegroundColor Blue
    git commit -m "Initial commit: MCP Servers with automated Docker builds

- Added Snowflake MCP Server with comprehensive functionality
- Added Databricks MCP Server with workspace integration  
- Added SQL Server MCP Server with ODBC support
- Configured GitHub Actions for automated Docker image building
- Multi-architecture support (linux/amd64, linux/arm64)
- Security scanning with Trivy
- Health checks and comprehensive testing
- SBOM generation for releases"
    
    # Set up remote
    $RemoteUrl = "https://github.com/$Username/$RepoName.git"
    Write-Host "🔗 Adding remote origin: $RemoteUrl" -ForegroundColor Blue
    
    try {
        git remote add origin $RemoteUrl
        Write-Host "✅ Remote origin added successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Remote origin may already exist, updating..." -ForegroundColor Yellow
        git remote set-url origin $RemoteUrl
    }
    
    # Set default branch to main
    git branch -M main
    
    Write-Host "🚀 Ready to push to GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: git push -u origin main" -ForegroundColor Cyan
    Write-Host "2. Go to your GitHub repository settings" -ForegroundColor Cyan
    Write-Host "3. Enable GitHub Actions if not already enabled" -ForegroundColor Cyan
    Write-Host "4. The workflow will automatically build Docker images on push to main" -ForegroundColor Cyan
}

function Show-WorkflowInfo {
    Write-Host ""
    Write-Host "🔄 GitHub Actions Workflow Information" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your repository includes a comprehensive GitHub Actions workflow that will:" -ForegroundColor Cyan
    Write-Host "✅ Automatically detect changes to any MCP server" -ForegroundColor White
    Write-Host "✅ Run security scans with Trivy" -ForegroundColor White
    Write-Host "✅ Build Docker images for all platforms (amd64, arm64)" -ForegroundColor White
    Write-Host "✅ Test container startup and security" -ForegroundColor White
    Write-Host "✅ Push images to GitHub Container Registry" -ForegroundColor White
    Write-Host "✅ Generate and attach SBOMs to releases" -ForegroundColor White
    Write-Host ""
    Write-Host "Triggers:" -ForegroundColor Yellow
    Write-Host "• Push to main branch → Build and publish latest images" -ForegroundColor White
    Write-Host "• Create version tag (v*) → Build and create GitHub release" -ForegroundColor White
    Write-Host "• Manual trigger → Build specific version" -ForegroundColor White
    Write-Host ""
    Write-Host "Docker Images will be available at:" -ForegroundColor Yellow
    Write-Host "• ghcr.io/$GitHubUsername/snowflake-mcp:latest" -ForegroundColor White
    Write-Host "• ghcr.io/$GitHubUsername/databricks-mcp:latest" -ForegroundColor White
    Write-Host "• ghcr.io/$GitHubUsername/sqlserver-mcp:latest" -ForegroundColor White
}

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Host "🚀 MCP Servers GitHub Setup" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    
    if (-not (Test-Git)) {
        return
    }
    
    if (-not $GitHubUsername) {
        $GitHubUsername = Read-Host "Enter your GitHub username"
        if (-not $GitHubUsername) {
            Write-Host "❌ GitHub username is required" -ForegroundColor Red
            return
        }
    }
    
    Write-Host "Repository: $RepoName" -ForegroundColor Cyan
    Write-Host "Username: $GitHubUsername" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Continue with setup? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Setup cancelled" -ForegroundColor Yellow
        return
    }
    
    Initialize-Repository -Username $GitHubUsername -RepoName $RepoName
    Show-WorkflowInfo
    
    Write-Host ""
    Write-Host "🎯 Quick Commands:" -ForegroundColor Green
    Write-Host "• Push to GitHub: git push -u origin main" -ForegroundColor Cyan
    Write-Host "• Build locally: .\deploy.ps1" -ForegroundColor Cyan
    Write-Host "• Build and push: .\deploy.ps1 -Push" -ForegroundColor Cyan
    Write-Host "• Create release: git tag v1.0.0 && git push origin v1.0.0" -ForegroundColor Cyan
}

# Run the main function
Main
