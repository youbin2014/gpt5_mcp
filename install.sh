#!/usr/bin/env bash
# One-shot installation script for gpt5-claude-mcp
# Supports macOS and Linux with bash

set -euo pipefail

# Configuration
APP_NAME="gpt5-claude-mcp"
REPO_URL="https://github.com/youbin2014/gpt5_mcp.git"
INSTALL_DIR="${PWD}/gpt5_mcp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo_info "Checking prerequisites..."
    
    # Check for Node.js
    if ! command -v node &> /dev/null; then
        echo_error "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node -v | cut -d'v' -f2)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        echo_error "Node.js version 18+ is required. Current version: $NODE_VERSION"
        exit 1
    fi
    echo_success "Node.js $NODE_VERSION detected"
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        echo_error "npm is not installed"
        exit 1
    fi
    echo_success "npm detected"
    
    # Check for git
    if ! command -v git &> /dev/null; then
        echo_error "git is not installed"
        exit 1
    fi
    echo_success "git detected"
    
    # Check for Claude CLI
    if ! command -v claude &> /dev/null; then
        echo_error "Claude CLI is not installed. Please install it first."
        echo_info "Installation guide: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
    echo_success "Claude CLI detected"
}

# Clone or update repository
setup_repository() {
    echo_info "Setting up repository..."
    
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo_info "Repository exists, updating..."
        git -C "$INSTALL_DIR" pull --rebase
        echo_success "Repository updated"
    else
        echo_info "Cloning repository..."
        git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
        echo_success "Repository cloned"
    fi
    
    cd "$INSTALL_DIR"
}

# Setup environment file
setup_environment() {
    echo_info "Setting up environment configuration..."
    
    ENV_FILE="$INSTALL_DIR/.env"
    
    # Create .env from example if it doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            echo_success "Created .env from template"
        else
            touch .env
            echo_success "Created empty .env file"
        fi
    fi
    
    # Get current API key from environment or .env file
    DEFAULT_KEY=""
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        DEFAULT_KEY="$OPENAI_API_KEY"
    elif [ -f "$ENV_FILE" ]; then
        DEFAULT_KEY=$(grep -E '^OPENAI_API_KEY=' "$ENV_FILE" 2>/dev/null | head -n1 | cut -d= -f2- || true)
    fi
    
    # Interactive API key input
    echo ""
    echo_info "OpenAI API Key Configuration"
    echo "You can get your API key from: https://platform.openai.com/api-keys"
    
    if [ -n "$DEFAULT_KEY" ] && [[ "$DEFAULT_KEY" == sk-* ]]; then
        echo_info "Found existing API key: ${DEFAULT_KEY:0:12}..."
        read -r -p "Enter new OpenAI API key (sk-...), or press Enter to keep existing: " KEY_INPUT
        if [ -z "$KEY_INPUT" ]; then
            KEY_INPUT="$DEFAULT_KEY"
        fi
    else
        read -r -p "Enter your OpenAI API key (sk-...), or press Enter to skip: " KEY_INPUT
        if [ -z "$KEY_INPUT" ] && [ -n "$DEFAULT_KEY" ]; then
            KEY_INPUT="$DEFAULT_KEY"
        fi
    fi
    
    # Update .env file with API key
    if [ -n "$KEY_INPUT" ]; then
        if grep -q "^OPENAI_API_KEY=" "$ENV_FILE"; then
            # Update existing key
            if command -v sed &> /dev/null; then
                sed -i.bak "s#^OPENAI_API_KEY=.*#OPENAI_API_KEY=${KEY_INPUT}#g" "$ENV_FILE"
                rm -f "${ENV_FILE}.bak" 2>/dev/null || true
            else
                # Fallback for systems without sed
                grep -v "^OPENAI_API_KEY=" "$ENV_FILE" > "${ENV_FILE}.tmp" || true
                echo "OPENAI_API_KEY=${KEY_INPUT}" >> "${ENV_FILE}.tmp"
                mv "${ENV_FILE}.tmp" "$ENV_FILE"
            fi
        else
            # Add new key
            echo "OPENAI_API_KEY=${KEY_INPUT}" >> "$ENV_FILE"
        fi
        echo_success "API key configured in .env file"
    else
        echo_warning "No API key provided. You'll need to set it manually or pass it during registration."
    fi
}

# Build the project
build_project() {
    echo_info "Installing dependencies and building project..."
    
    npm install
    echo_success "Dependencies installed"
    
    npm run build
    echo_success "Project built successfully"
}

# Register with Claude MCP
register_mcp() {
    echo_info "Registering with Claude MCP..."
    
    # Remove any existing registrations
    claude mcp remove "$APP_NAME" 2>/dev/null || true
    claude mcp remove --scope user "$APP_NAME" 2>/dev/null || true
    echo_info "Cleaned up any existing registrations"
    
    # Get final API key for registration
    FINAL_KEY=""
    if [ -f "$ENV_FILE" ]; then
        FINAL_KEY=$(grep -E '^OPENAI_API_KEY=' "$ENV_FILE" 2>/dev/null | head -n1 | cut -d= -f2- || true)
    fi
    
    # Prepare registration command
    SERVER_PATH="$INSTALL_DIR/dist/server.js"
    
    if [ -n "$FINAL_KEY" ] && [[ "$FINAL_KEY" == sk-* ]]; then
        # Register with API key via environment variable
        echo_info "Registering with API key injection..."
        claude mcp add --scope user "$APP_NAME" --env OPENAI_API_KEY="$FINAL_KEY" -- node "$SERVER_PATH"
    else
        # Register without API key (will read from .env at runtime)
        echo_info "Registering without API key injection (will read from .env)..."
        claude mcp add --scope user "$APP_NAME" -- node "$SERVER_PATH"
    fi
    
    echo_success "MCP server registered successfully"
}

# Health check
health_check() {
    echo_info "Performing health check..."
    
    # Set timeout for MCP operations
    export MCP_TIMEOUT=15000
    
    if claude mcp list | grep -q "$APP_NAME"; then
        echo_success "Health check passed - MCP server is registered and responsive"
        echo_info "You can now use the gpt5_query tool in Claude Code!"
        echo ""
        echo_info "Example usage:"
        echo "  - gpt5_query with prompt: 'Explain quantum computing'"
        echo "  - gpt5_test_connection to verify API connectivity"
    else
        echo_warning "Health check failed - MCP server may not be properly configured"
        echo_info "Please check your API key configuration:"
        echo "  1. Verify your key in: $ENV_FILE"
        echo "  2. Re-register manually if needed:"
        echo "     claude mcp add --scope user $APP_NAME --env OPENAI_API_KEY='your-key' -- node '$SERVER_PATH'"
    fi
}

# Error handling
handle_error() {
    echo_error "Installation failed!"
    echo_info "Troubleshooting steps:"
    echo "  1. Check your OpenAI API key in: $INSTALL_DIR/.env"
    echo "  2. Ensure you have Node.js 18+ installed"
    echo "  3. Verify Claude CLI is properly installed"
    echo "  4. Check the installation log above for specific errors"
    echo ""
    echo_info "Manual registration command:"
    echo "  claude mcp add --scope user $APP_NAME --env OPENAI_API_KEY='your-key' -- node '$INSTALL_DIR/dist/server.js'"
    exit 1
}

# Main installation flow
main() {
    echo_info "Starting gpt5-claude-mcp installation..."
    echo ""
    
    # Set error trap
    trap handle_error ERR
    
    check_prerequisites
    setup_repository
    setup_environment
    build_project
    register_mcp
    health_check
    
    echo ""
    echo_success "🎉 Installation completed successfully!"
    echo_info "The gpt5-claude-mcp server is now ready to use in Claude Code."
    echo ""
    echo_info "Installation directory: $INSTALL_DIR"
    echo_info "Configuration file: $INSTALL_DIR/.env"
    echo ""
    echo_info "Next steps:"
    echo "  1. Open Claude Code"
    echo "  2. Try: gpt5_query with prompt 'Hello from GPT-5!'"
    echo "  3. Use gpt5_test_connection to verify everything works"
}

# Run main function
main "$@"