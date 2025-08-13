#!/bin/bash

# GPT-5 Claude MCP - One-Click Local Installation Script
# This script sets up the GPT-5 MCP server in the current project directory

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

# Always install in current directory for project-local MCP configuration
INSTALL_DIR="$(pwd)/gpt5_mcp"
REPO_URL="https://github.com/youbin2014/gpt5_mcp.git"

log_header "GPT-5 Claude MCP Local Installation"

echo "🎯 This script will install GPT-5 MCP server in your current project:"
echo "   • Download GPT-5 MCP server to current directory"
echo "   • Install dependencies and build TypeScript"
echo "   • Configure environment settings"
echo "   • Register MCP server with Claude Code for this project"
echo "   • Validate installation and connection"
echo ""
echo "📍 Installation Directory: $INSTALL_DIR"
echo "📍 MCP Registration: Project-local configuration"
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
    log_error "Claude Code CLI not found. Please install Claude Code first."
    log_info "Visit: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

log_success "Claude Code CLI detected"

# Clean up any existing installation
log_header "Preparing Installation"

# Remove existing MCP server if registered
if claude mcp list 2>/dev/null | grep -q "gpt5-claude-mcp"; then
    log_warning "Removing existing gpt5-claude-mcp server registration..."
    claude mcp remove gpt5-claude-mcp 2>/dev/null || true
    log_success "Existing MCP server removed"
fi

# Remove existing installation directory
if [ -d "$INSTALL_DIR" ]; then
    log_warning "Removing existing installation directory..."
    rm -rf "$INSTALL_DIR"
    log_success "Existing installation cleaned up"
fi

# Download repository
log_header "Downloading GPT-5 MCP Server"

log_info "Cloning repository to $INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"
log_success "Repository downloaded successfully"

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

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    log_info "Creating .env file from template..."
    cp config/example.env .env
else
    log_success "Environment file already exists"
fi

# Check if API key is configured
log_info "Checking API key configuration..."

if grep -q "sk-your-openai-api-key-here" .env; then
    log_warning "Placeholder API key detected"
    API_KEY_NEEDED=true
elif ! grep -q "OPENAI_API_KEY=sk-" .env; then
    log_warning "No valid API key found"
    API_KEY_NEEDED=true
else
    log_success "Valid API key appears to be configured"
    API_KEY_NEEDED=false
fi

if [ "$API_KEY_NEEDED" = "true" ]; then
    echo ""
    echo "🔑 IMPORTANT: OpenAI API Key Required"
    echo ""
    echo "You need an OpenAI API key to use GPT-5."
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""
    
    # Always try to get user input, even in piped mode
    echo "You have 15 seconds to respond (or the script will continue without configuring the API key):"
    read -t 15 -p "Do you want to configure your OpenAI API key now? (y/n): " configure_now || configure_now="n"
    
    if [ -z "$configure_now" ]; then
        configure_now="n"
        echo ""
        log_info "No response received within 15 seconds, skipping API key configuration"
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
fi

# Configure Claude Code MCP for this project
log_header "Configuring Claude Code Integration"

# Build the MCP add command with absolute path
MCP_SERVER_PATH="$(pwd)/dist/server.js"
MCP_COMMAND="claude mcp add gpt5-claude-mcp \"node $MCP_SERVER_PATH\""

log_info "Registering MCP server for this project..."
echo "Running: $MCP_COMMAND"

if eval "$MCP_COMMAND"; then
    log_success "MCP server registered successfully for this project"
    
    # Verify the installation
    if claude mcp list 2>/dev/null | grep -q "gpt5-claude-mcp"; then
        log_success "MCP server registration verified"
    else
        log_warning "MCP server registration may not be working properly"
    fi
else
    log_error "Failed to register MCP server with Claude Code"
    log_info "You can manually register it later with:"
    echo "  $MCP_COMMAND"
    exit 1
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

# Project setup script for easy re-registration
cat > mcp-setup.sh << EOF
#!/bin/bash
# MCP setup script for this project
echo "🔧 Setting up GPT-5 MCP for this project..."
claude mcp remove gpt5-claude-mcp 2>/dev/null || true
claude mcp add gpt5-claude-mcp "node \$(dirname \$0)/dist/server.js"
echo "✅ GPT-5 MCP server configured for this project"
EOF

chmod +x mcp-setup.sh

log_success "Convenience scripts created (start.sh, test.sh, mcp-setup.sh)"

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

# Test MCP server registration
log_info "Testing MCP server registration..."
cd ..  # Go back to parent directory to test registration scope

if claude mcp list 2>/dev/null | grep -q "gpt5-claude-mcp"; then
    log_success "MCP server is properly registered for this project"
else
    log_warning "MCP server registration issue detected"
    log_info "Re-registering MCP server..."
    claude mcp add gpt5-claude-mcp "node $MCP_SERVER_PATH"
fi

# Installation complete
log_header "Installation Complete!"

echo ""
echo "🎉 GPT-5 Claude MCP Server has been installed successfully!"
echo ""
echo "📍 Installation Directory: $INSTALL_DIR"
echo "📍 Project Scope: MCP server registered for current project"
echo ""
echo "📂 Files created in this project:"
echo "   • gpt5_mcp/dist/server.js - MCP server"
echo "   • gpt5_mcp/.env - Configuration file"
echo "   • gpt5_mcp/mcp-setup.sh - Re-registration script"
echo "   • gpt5_mcp/test.sh - Connection test script"
echo ""
echo "🔧 Next steps:"
echo "   1. Ensure your OpenAI API key is configured in gpt5_mcp/.env"
echo "   2. Test the connection: cd gpt5_mcp && ./test.sh"
echo "   3. GPT-5 is ready to use in Claude Code!"
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
echo "🔄 For other projects:"
echo "   • Copy the gpt5_mcp folder to other project directories"
echo "   • Run: cd gpt5_mcp && ./mcp-setup.sh"
echo ""
echo "🆘 Troubleshooting:"
echo "   • Test connection: cd gpt5_mcp && ./test.sh"
echo "   • Re-register: cd gpt5_mcp && ./mcp-setup.sh"
echo "   • View logs: Check console output when running Claude Code"
echo ""
echo "📚 Documentation: See gpt5_mcp/README.md for detailed usage instructions"
echo ""

log_success "Setup completed successfully! 🚀"