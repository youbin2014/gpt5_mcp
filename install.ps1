# One-shot installation script for gpt5-claude-mcp
# Supports Windows with PowerShell

param(
    [string]$InstallPath = $PWD
)

$ErrorActionPreference = "Stop"

# Configuration
$APP_NAME = "gpt5-claude-mcp"
$REPO_URL = "https://github.com/youbin2014/gpt5_mcp.git"
$INSTALL_DIR = Join-Path $InstallPath "gpt5_mcp"

# Color functions for output
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
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

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check for Node.js
    try {
        $nodeVersion = & node --version 2>$null
        if (-not $nodeVersion) {
            throw "Node.js not found"
        }
        
        # Parse version and check minimum requirement
        $version = $nodeVersion -replace 'v', ''
        $majorVersion = [int]($version -split '\.')[0]
        
        if ($majorVersion -lt 18) {
            throw "Node.js version 18+ is required. Current version: $nodeVersion"
        }
        
        Write-Success "Node.js $nodeVersion detected"
    }
    catch {
        Write-Error "Node.js is not installed or version is too old. Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    }
    
    # Check for npm
    try {
        $npmVersion = & npm --version 2>$null
        if (-not $npmVersion) {
            throw "npm not found"
        }
        Write-Success "npm $npmVersion detected"
    }
    catch {
        Write-Error "npm is not installed"
        exit 1
    }
    
    # Check for git
    try {
        $gitVersion = & git --version 2>$null
        if (-not $gitVersion) {
            throw "git not found"
        }
        Write-Success "git detected"
    }
    catch {
        Write-Error "git is not installed"
        exit 1
    }
    
    # Check for Claude CLI
    try {
        $claudeVersion = & claude --version 2>$null
        if (-not $claudeVersion) {
            throw "Claude CLI not found"
        }
        Write-Success "Claude CLI detected"
    }
    catch {
        Write-Error "Claude CLI is not installed. Please install it first."
        Write-Info "Installation guide: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    }
}

# Clone or update repository
function Initialize-Repository {
    Write-Info "Setting up repository..."
    
    if (Test-Path (Join-Path $INSTALL_DIR ".git")) {
        Write-Info "Repository exists, updating..."
        Set-Location $INSTALL_DIR
        & git pull --rebase
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update repository"
        }
        Write-Success "Repository updated"
    }
    else {
        Write-Info "Cloning repository..."
        & git clone --depth=1 $REPO_URL $INSTALL_DIR
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone repository"
        }
        Write-Success "Repository cloned"
        Set-Location $INSTALL_DIR
    }
}

# Setup environment file
function Initialize-Environment {
    Write-Info "Setting up environment configuration..."
    
    $envFile = Join-Path $INSTALL_DIR ".env"
    
    # Create .env from example if it doesn't exist
    if (-not (Test-Path $envFile)) {
        $exampleFile = Join-Path $INSTALL_DIR ".env.example"
        if (Test-Path $exampleFile) {
            Copy-Item $exampleFile $envFile
            Write-Success "Created .env from template"
        }
        else {
            New-Item -ItemType File -Path $envFile -Force | Out-Null
            Write-Success "Created empty .env file"
        }
    }
    
    # Get current API key from environment or .env file
    $defaultKey = ""
    if ($env:OPENAI_API_KEY) {
        $defaultKey = $env:OPENAI_API_KEY
    }
    elseif (Test-Path $envFile) {
        $envContent = Get-Content $envFile -ErrorAction SilentlyContinue
        $keyLine = $envContent | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
        if ($keyLine) {
            $defaultKey = ($keyLine -split '=', 2)[1]
        }
    }
    
    # Interactive API key input
    Write-Host ""
    Write-Info "OpenAI API Key Configuration"
    Write-Host "You can get your API key from: https://platform.openai.com/api-keys"
    Write-Host ""
    
    $keyInput = ""
    if ($defaultKey -and $defaultKey.StartsWith("sk-")) {
        Write-Info "Found existing API key: $($defaultKey.Substring(0, 12))..."
        $keyInput = Read-Host "Enter new OpenAI API key (sk-...), or press Enter to keep existing"
        if ([string]::IsNullOrWhiteSpace($keyInput)) {
            $keyInput = $defaultKey
        }
    }
    else {
        $keyInput = Read-Host "Enter your OpenAI API key (sk-...), or press Enter to skip"
        if ([string]::IsNullOrWhiteSpace($keyInput) -and $defaultKey) {
            $keyInput = $defaultKey
        }
    }
    
    # Update .env file with API key
    if (-not [string]::IsNullOrWhiteSpace($keyInput)) {
        $envContent = @()
        if (Test-Path $envFile) {
            $envContent = Get-Content $envFile
        }
        
        $updatedContent = @()
        $keyUpdated = $false
        
        foreach ($line in $envContent) {
            if ($line -match '^OPENAI_API_KEY=') {
                $updatedContent += "OPENAI_API_KEY=$keyInput"
                $keyUpdated = $true
            }
            else {
                $updatedContent += $line
            }
        }
        
        if (-not $keyUpdated) {
            $updatedContent += "OPENAI_API_KEY=$keyInput"
        }
        
        Set-Content -Path $envFile -Value $updatedContent -Encoding UTF8
        Write-Success "API key configured in .env file"
    }
    else {
        Write-Warning "No API key provided. You'll need to set it manually or pass it during registration."
    }
    
    return $envFile
}

# Build the project
function Build-Project {
    Write-Info "Installing dependencies and building project..."
    
    & npm install
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install dependencies"
    }
    Write-Success "Dependencies installed"
    
    & npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build project"
    }
    Write-Success "Project built successfully"
}

# Register with Claude MCP
function Register-MCP {
    param([string]$EnvFile)
    
    Write-Info "Registering with Claude MCP..."
    
    # Remove any existing registrations
    try {
        & claude mcp remove $APP_NAME 2>$null
    }
    catch {
        # Ignore errors when removing non-existent registrations
    }
    
    try {
        & claude mcp remove --scope user $APP_NAME 2>$null
    }
    catch {
        # Ignore errors when removing non-existent registrations
    }
    
    Write-Info "Cleaned up any existing registrations"
    
    # Get final API key for registration
    $finalKey = ""
    if (Test-Path $EnvFile) {
        $envContent = Get-Content $EnvFile -ErrorAction SilentlyContinue
        $keyLine = $envContent | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
        if ($keyLine) {
            $finalKey = ($keyLine -split '=', 2)[1]
        }
    }
    
    # Prepare registration command
    $serverPath = Join-Path $INSTALL_DIR "dist\server.js"
    
    if ($finalKey -and $finalKey.StartsWith("sk-")) {
        # Register with API key via environment variable
        Write-Info "Registering with API key injection..."
        & claude mcp add --scope user $APP_NAME --env OPENAI_API_KEY="$finalKey" -- node "`"$serverPath`""
    }
    else {
        # Register without API key (will read from .env at runtime)
        Write-Info "Registering without API key injection (will read from .env)..."
        & claude mcp add --scope user $APP_NAME -- node "`"$serverPath`""
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register MCP server"
    }
    
    Write-Success "MCP server registered successfully"
}

# Health check
function Test-Health {
    Write-Info "Performing health check..."
    
    # Set timeout for MCP operations
    $env:MCP_TIMEOUT = "15000"
    
    try {
        $mcpList = & claude mcp list 2>$null
        if ($mcpList -and ($mcpList -match $APP_NAME)) {
            Write-Success "Health check passed - MCP server is registered and responsive"
            Write-Info "You can now use the gpt5_query tool in Claude Code!"
            Write-Host ""
            Write-Info "Example usage:"
            Write-Host "  - gpt5_query with prompt: 'Explain quantum computing'"
            Write-Host "  - gpt5_test_connection to verify API connectivity"
            return $true
        }
        else {
            Write-Warning "Health check failed - MCP server may not be properly configured"
            Write-Info "Please check your API key configuration:"
            Write-Host "  1. Verify your key in: $envFile"
            Write-Host "  2. Re-register manually if needed:"
            Write-Host "     claude mcp add --scope user $APP_NAME --env OPENAI_API_KEY='your-key' -- node `"$serverPath`""
            return $false
        }
    }
    catch {
        Write-Warning "Health check failed with error: $($_.Exception.Message)"
        return $false
    }
}

# Error handling
function Handle-Error {
    param([string]$ErrorMessage)
    
    Write-Error "Installation failed: $ErrorMessage"
    Write-Info "Troubleshooting steps:"
    Write-Host "  1. Check your OpenAI API key in: $INSTALL_DIR\.env"
    Write-Host "  2. Ensure you have Node.js 18+ installed"
    Write-Host "  3. Verify Claude CLI is properly installed"
    Write-Host "  4. Check the installation log above for specific errors"
    Write-Host ""
    Write-Info "Manual registration command:"
    Write-Host "  claude mcp add --scope user $APP_NAME --env OPENAI_API_KEY='your-key' -- node `"$INSTALL_DIR\dist\server.js`""
    exit 1
}

# Main installation flow
function Start-Installation {
    Write-Info "Starting gpt5-claude-mcp installation..."
    Write-Host ""
    
    try {
        Test-Prerequisites
        Initialize-Repository
        $envFile = Initialize-Environment
        Build-Project
        Register-MCP -EnvFile $envFile
        Test-Health
        
        Write-Host ""
        Write-Success "🎉 Installation completed successfully!"
        Write-Info "The gpt5-claude-mcp server is now ready to use in Claude Code."
        Write-Host ""
        Write-Info "Installation directory: $INSTALL_DIR"
        Write-Info "Configuration file: $INSTALL_DIR\.env"
        Write-Host ""
        Write-Info "Next steps:"
        Write-Host "  1. Open Claude Code"
        Write-Host "  2. Try: gpt5_query with prompt 'Hello from GPT-5!'"
        Write-Host "  3. Use gpt5_test_connection to verify everything works"
    }
    catch {
        Handle-Error $_.Exception.Message
    }
}

# Run main function
Start-Installation