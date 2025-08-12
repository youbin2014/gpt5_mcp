#!/bin/bash

# GPT-5 Claude MCP - One-Click Installation Script
# This script sets up the GPT-5 MCP server and integrates it with Claude Code

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "\n${BLUE}🚀 $1${NC}"
    echo "=================================="
}

# Check if running from curl | bash
if [ -z "$BASH_SOURCE" ]; then
    INSTALL_DIR="$HOME/.gpt5-claude-mcp"
    REPO_URL="https://github.com/youbin2014/gpt5_mcp.git"
    IS_REMOTE_INSTALL=true
else
    INSTALL_DIR="$(pwd)"
    IS_REMOTE_INSTALL=false
fi

log_header "GPT-5 Claude MCP Installation"

echo "🎯 This script will:"
echo "   • Install GPT-5 MCP server dependencies"
echo "   • Build the TypeScript project"  
echo "   • Configure Claude Code integration"
echo "   • Set up environment configuration"
echo "   • Validate the installation"
echo ""

# Check prerequisites
log_header "Checking Prerequisites"

# Check Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d 'v' -f2)
NODE_MAJOR=$(echo $NODE_VERSION | cut -d '.' -f1)

if [ "$NODE_MAJOR" -lt 18 ]; then
    log_error "Node.js version $NODE_VERSION is too old. Please install Node.js 18+ and try again."
    exit 1
fi

log_success "Node.js version $NODE_VERSION detected"

# Check npm
if ! command -v npm &> /dev/null; then
    log_error "npm is not installed. Please install npm and try again."
    exit 1
fi

log_success "npm $(npm -v) detected"

# Check Claude Code
if ! command -v claude &> /dev/null; then
    log_warning "Claude Code CLI not found in PATH"
    log_info "You may need to install Claude Code or add it to your PATH"
    log_info "Visit: https://docs.anthropic.com/en/docs/claude-code"
else
    log_success "Claude Code CLI detected"
fi

# Download repository if remote install
if [ "$IS_REMOTE_INSTALL" = true ]; then
    log_header "Downloading GPT-5 MCP Server"
    
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Directory $INSTALL_DIR already exists. Backing up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%s)"
    fi
    
    log_info "Cloning repository to $INSTALL_DIR"
    git clone "https://github.com/youbin2014/gpt5_mcp.git" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log_success "Repository downloaded successfully"
fi

# Install dependencies
log_header "Installing Dependencies"

log_info "Running npm install..."
npm install

log_success "Dependencies installed successfully"

# Build TypeScript
log_header "Building TypeScript Project"

log_info "Compiling TypeScript to JavaScript..."
npm run build

log_success "TypeScript compilation completed"

# Set up environment configuration
log_header "Setting Up Environment Configuration"

if [ ! -f ".env" ]; then
    log_info "Creating .env file from template..."
    cp config/example.env .env
    
    echo ""
    echo "🔑 IMPORTANT: OpenAI API Key Required"
    echo ""
    echo "You need an OpenAI API key to use GPT-5."
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""
    
    # Check if running in non-interactive mode
    if [ -t 0 ]; then
        # Interactive mode - ask user
        read -p "Do you want to configure your OpenAI API key now? (y/n): " configure_now
    else
        # Non-interactive mode (e.g., CI/CD) - skip configuration
        configure_now="n"
        log_info "Non-interactive mode detected, skipping API key configuration"
    fi
    
    if [[ $configure_now =~ ^[Yy]$ ]]; then
        echo ""
        echo "Please enter your OpenAI API key (starts with 'sk-'):"
        read -s api_key  # -s hides the input for security
        echo ""
        
        if [[ $api_key == sk-* ]]; then
            # Replace the API key in .env file
            sed -i.bak "s/sk-your-openai-api-key-here/$api_key/g" .env
            rm .env.bak 2>/dev/null || true
            log_success "OpenAI API key configured successfully!"
        else
            log_warning "Invalid API key format. Please edit .env file manually later."
            log_info "API keys should start with 'sk-'"
        fi
    else
        echo ""
        echo "You can configure your API key later by editing the .env file:"
        echo "File location: $(pwd)/.env"
        echo ""
        echo "To edit the file manually, run one of these commands:"
        echo "  • code .env      (VS Code)"
        echo "  • nano .env      (Nano editor)"
        echo "  • vim .env       (Vim editor)"
        echo ""
        echo "Replace 'sk-your-openai-api-key-here' with your actual API key."
        log_warning "Remember to configure your API key before using the server"
    fi
else
    log_success "Environment file already exists"
fi

# Test configuration
log_header "Testing Configuration"

log_info "Validating environment configuration..."

# Check if OPENAI_API_KEY is set
if grep -q "sk-your-openai-api-key-here" .env || ! grep -q "OPENAI_API_KEY=sk-" .env; then
    log_warning "OpenAI API key not configured properly"
    log_info "Please edit .env file and add your API key before proceeding"
else
    log_success "OpenAI API key appears to be configured"
    
    # Test the server
    log_info "Testing GPT-5 connection..."
    timeout 10s npm run dev -- --test-only 2>/dev/null || {
        log_warning "Connection test timed out or failed"
        log_info "This may be normal if API key is not yet configured"
    }
fi

# Configure Claude Code MCP
log_header "Configuring Claude Code Integration"

# Build the MCP add command
MCP_COMMAND="claude mcp add gpt5-claude-mcp \"node $(pwd)/dist/server.js\""

log_info "Adding MCP server to Claude Code..."
echo "Running: $MCP_COMMAND"

if command -v claude &> /dev/null; then
    if eval "$MCP_COMMAND"; then
        log_success "MCP server added to Claude Code successfully"
    else
        log_error "Failed to add MCP server to Claude Code"
        log_info "You can manually add it later with:"
        echo "  $MCP_COMMAND"
    fi
else
    log_warning "Claude Code not found. Manual configuration required:"
    echo ""
    echo "After installing Claude Code, run:"
    echo "  $MCP_COMMAND"
    echo ""
fi

# Create convenience scripts
log_header "Creating Convenience Scripts"

# Start script
cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting GPT-5 MCP Server..."
cd "$(dirname "$0")"
node dist/server.js
EOF

chmod +x start.sh

# Test script
cat > test.sh << 'EOF'
#!/bin/bash
echo "🔍 Testing GPT-5 MCP Server..."
cd "$(dirname "$0")"
export NODE_ENV=test
node dist/server.js --test-connection
EOF

chmod +x test.sh

log_success "Convenience scripts created (start.sh, test.sh)"

# Final validation
log_header "Final Validation"

# Check build output
if [ -f "dist/server.js" ]; then
    log_success "Server build completed successfully"
else
    log_error "Server build failed - dist/server.js not found"
    exit 1
fi

# Check environment
if [ -f ".env" ]; then
    log_success "Environment configuration file exists"
else
    log_error "Environment configuration file missing"
    exit 1
fi

# Installation complete
log_header "Installation Complete!"

echo ""
echo "🎉 GPT-5 Claude MCP Server has been installed successfully!"
echo ""
echo "📁 Installation directory: $(pwd)"
echo ""
echo "🔧 Next steps:"
echo "   1. Ensure your OpenAI API key is configured in .env"
echo "   2. Test the connection: ./test.sh"
echo "   3. Start using GPT-5 in Claude Code!"
echo ""
echo "💬 How to use (Natural Conversation - Recommended):"
echo "   Just ask Claude Code things like:"
echo "   • \"Use GPT-5 to explain quantum computing\""
echo "   • \"Ask GPT-5-mini for a quick code review\""
echo "   • \"Get GPT-5's opinion on this with high verbosity\""
echo ""
echo "🔧 Advanced usage (Direct tool calls):"
echo "   • gpt5_query({\"prompt\": \"Your question\"})"
echo "   • gpt5_query({\"prompt\": \"Question\", \"model\": \"gpt-5-mini\"})"
echo ""
echo "🆘 Troubleshooting:"
echo "   • Test connection: ./test.sh"
echo "   • View logs: Check console output when running Claude Code"
echo "   • Configuration: Edit .env file for API key and settings"
echo ""
echo "📚 Documentation: See README.md for detailed usage instructions"
echo ""

log_success "Setup completed successfully! 🚀"