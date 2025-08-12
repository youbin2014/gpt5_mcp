#!/bin/bash

# GPT-5 Claude MCP - Local Installation Script
# Install directly in current project directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo ""
echo "🎯 GPT-5 Claude MCP - Local Project Installation"
echo "================================================"
echo ""
echo "This will install GPT-5 MCP server in the current directory:"
echo "📍 $(pwd)"
echo ""

read -p "Continue? (y/n): " continue_install
if [[ ! $continue_install =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Download and run the main installer
log_header "Starting Local Installation"

log_info "Downloading installation script..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh > /tmp/gpt5_install.sh
elif command -v wget >/dev/null 2>&1; then
    wget -qO /tmp/gpt5_install.sh https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh
else
    log_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

log_success "Installation script downloaded"

# Run the installer in local mode
log_info "Running local installation..."
echo "y" | bash /tmp/gpt5_install.sh

# Clean up
rm -f /tmp/gpt5_install.sh

echo ""
log_success "Local installation completed!"
echo ""
echo "🎯 Quick Start:"
echo "   1. Edit .env file to add your OpenAI API key"
echo "   2. Run: ./test.sh"
echo "   3. Use GPT-5 in Claude Code!"
echo ""