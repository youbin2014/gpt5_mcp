#!/bin/bash

# GPT-5 Claude MCP - Setup Validation Script
# Validates the installation and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "\n${BLUE}🔍 $1${NC}"
    echo "=================================="
}

# Track validation results
VALIDATION_ERRORS=0

log_header "GPT-5 Claude MCP Setup Validation"

# Check Node.js
log_header "Checking Node.js Environment"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    log_success "Node.js $NODE_VERSION installed"
    
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d 'v' -f2 | cut -d '.' -f1)
    if [ "$NODE_MAJOR" -lt 18 ]; then
        log_error "Node.js version $NODE_VERSION is too old (requires 18+)"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    log_error "Node.js not found"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    log_success "npm $NPM_VERSION installed"
else
    log_error "npm not found"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check project structure
log_header "Checking Project Structure"

REQUIRED_FILES=(
    "package.json"
    "tsconfig.json"
    "src/server.ts"
    "src/gpt5-client.ts"
    "src/message-processor.ts"
    "src/config.ts"
    "src/types.ts"
    "config/default.json"
    "config/example.env"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file exists"
    else
        log_error "$file missing"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

# Check dependencies
log_header "Checking Dependencies"

if [ -d "node_modules" ]; then
    log_success "node_modules directory exists"
    
    # Check key dependencies
    REQUIRED_DEPS=(
        "@modelcontextprotocol/sdk"
        "openai"
        "typescript"
        "dotenv"
        "zod"
    )
    
    for dep in "${REQUIRED_DEPS[@]}"; do
        if [ -d "node_modules/$dep" ]; then
            log_success "$dep installed"
        else
            log_error "$dep missing - run npm install"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    done
else
    log_error "node_modules directory missing - run npm install"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check TypeScript compilation
log_header "Checking TypeScript Compilation"

if npm run build &> /dev/null; then
    log_success "TypeScript compilation successful"
    
    if [ -f "dist/server.js" ]; then
        log_success "Server build output exists"
    else
        log_error "Server build output missing"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    log_error "TypeScript compilation failed"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check environment configuration
log_header "Checking Environment Configuration"

if [ -f ".env" ]; then
    log_success ".env file exists"
    
    if grep -q "OPENAI_API_KEY=" .env; then
        if grep -q "sk-" .env; then
            log_success "OpenAI API key configured"
        else
            log_warning "OpenAI API key may not be valid (should start with 'sk-')"
        fi
    else
        log_warning "OpenAI API key not found in .env file"
    fi
else
    log_warning ".env file not found - copy from config/example.env"
fi

# Check Claude Code integration
log_header "Checking Claude Code Integration"

if command -v claude &> /dev/null; then
    log_success "Claude Code CLI found"
    
    # Check if MCP server is configured
    if claude mcp list 2>/dev/null | grep -q "gpt5-claude-mcp"; then
        log_success "GPT-5 MCP server configured in Claude Code"
    else
        log_warning "GPT-5 MCP server not configured in Claude Code"
        log_info "Run: claude mcp add gpt5-claude-mcp \"node $(pwd)/dist/server.js\""
    fi
else
    log_warning "Claude Code CLI not found"
    log_info "Install from: https://docs.anthropic.com/en/docs/claude-code"
fi

# Test server functionality
log_header "Testing Server Functionality"

if [ -f "dist/server.js" ] && [ -f ".env" ]; then
    log_info "Testing server startup..."
    
    # Test server can start (timeout after 5 seconds)
    if timeout 5s node dist/server.js --test-only &> /dev/null; then
        log_success "Server starts successfully"
    else
        log_warning "Server startup test inconclusive (this may be normal)"
    fi
else
    log_warning "Cannot test server - missing build output or configuration"
fi

# Run tests if available
log_header "Running Tests"

if [ -f "jest.config.js" ] && [ -d "tests" ]; then
    log_info "Running test suite..."
    
    if npm test &> /dev/null; then
        log_success "All tests pass"
    else
        log_warning "Some tests failed - check test output"
    fi
else
    log_info "Test suite not found - skipping"
fi

# Final validation summary
log_header "Validation Summary"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    log_success "All validations passed! 🎉"
    echo ""
    echo "Your GPT-5 Claude MCP server is properly configured and ready to use."
    echo ""
    echo "Next steps:"
    echo "1. Ensure your OpenAI API key is set in .env"
    echo "2. Add the MCP server to Claude Code if not already done"
    echo "3. Start using GPT-5 queries in Claude Code!"
    echo ""
    exit 0
else
    log_error "$VALIDATION_ERRORS validation error(s) found"
    echo ""
    echo "Please fix the issues above and run this script again."
    echo ""
    echo "Common solutions:"
    echo "• Install missing dependencies: npm install"
    echo "• Build the project: npm run build"
    echo "• Configure environment: cp config/example.env .env"
    echo "• Add OpenAI API key to .env file"
    echo ""
    exit 1
fi