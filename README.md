# 🤖 GPT-5 Claude MCP Server

**Seamlessly integrate OpenAI's GPT-5 into Claude Code workflows with one-click installation.**

[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=flat&logo=node.js&logoColor=white)](https://nodejs.org/)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--5-412991?style=flat&logo=openai&logoColor=white)](https://openai.com/gpt-5/)
[![MCP](https://img.shields.io/badge/MCP-Compatible-blue?style=flat)](https://modelcontextprotocol.io/)

## 🎯 Overview

This repository provides a **Model Context Protocol (MCP) server** that allows Claude Code users to query OpenAI's GPT-5 models directly from their Claude Code environment. Instead of using Claude's API, you can seamlessly switch to GPT-5 for specific queries while maintaining your familiar Claude Code workflow.

### ✨ Key Features

- 🔧 **One-Click Installation** - Automated setup with Claude Code integration
- 🚀 **GPT-5 Model Support** - Access to `gpt-5`, `gpt-5-mini`, and `gpt-5-nano`
- ⚙️ **Advanced Parameters** - Control verbosity, reasoning effort, and temperature
- 🔐 **Secure Configuration** - Environment-based API key management
- 📊 **Usage Tracking** - Token usage and performance metrics
- 🛡️ **Error Handling** - Graceful fallbacks and comprehensive error messages
- 🔄 **Message Processing** - Intelligent Claude ↔ GPT-5 format conversion

## 📦 Quick Installation

### 🚀 One-Shot Installation (Recommended)

Choose your platform and run the appropriate command:

#### macOS / Linux (bash)
```bash
# Download and run installation script
curl -fsSL https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh | bash

# Or download and inspect first (recommended)
curl -fsSL https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

#### Windows (PowerShell)
```powershell
# Download and run installation script
iwr -useb https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.ps1 | iex

# Or download and inspect first (recommended)
Invoke-WebRequest -Uri https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.ps1 -OutFile install.ps1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

**What the installation script does:**
1. ✅ Checks prerequisites (Node.js 18+, npm, git, Claude CLI)
2. 🔄 Clones/updates the repository to `./gpt5_mcp/`
3. 🔑 Interactively configures your OpenAI API key
4. 📦 Installs dependencies and builds the project
5. 🔗 Registers with Claude Code using `--scope user`
6. ✅ Performs health checks and validation

### 🛠️ Manual Installation

If you prefer to install manually:

```bash
# Clone the repository
git clone https://github.com/youbin2014/gpt5_mcp.git
cd gpt5_mcp

# Copy environment template and configure
cp .env.example .env
# Edit .env file with your OpenAI API key

# Install dependencies and build
npm install
npm run build

# Register with Claude Code (user scope)
claude mcp add --scope user gpt5-claude-mcp -- node "$(pwd)/dist/server.js"
```

### 🧪 Development Setup

For developers wanting to contribute or customize:

```bash
# Clone repository
git clone https://github.com/youbin2014/gpt5_mcp.git
cd gpt5_mcp

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your API key

# Development mode with hot reload
npm run dev

# Or build and register for testing
npm run build
claude mcp add --scope user gpt5-claude-mcp-dev -- node "$(pwd)/dist/server.js"
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the project root with your configuration:

```env
# Required: OpenAI API Key
OPENAI_API_KEY=sk-your-openai-api-key-here

# Optional: Model Configuration
GPT5_DEFAULT_MODEL=gpt-5

# Optional: Timeout and Retry Settings
OPENAI_TIMEOUT=60000
MAX_RETRIES=3
RETRY_DELAY=1000

# Optional: Logging Configuration
LOG_LEVEL=info
LOG_REQUESTS=false
LOG_RESPONSES=false
```

### Getting an OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign in to your account or create a new one
3. Navigate to "API Keys" section
4. Click "Create new secret key"
5. Copy the key and add it to your `.env` file

## 🚀 Usage

Once installed, you can seamlessly use GPT-5 in Claude Code through natural conversation:

### 💬 Natural Conversation (Recommended)

Just chat with Claude Code and request GPT-5 when needed:

```
You: "Can you use GPT-5 to explain quantum computing in simple terms?"

You: "Ask GPT-5 to help me optimize this React component: [paste your code]"

You: "Use GPT-5-mini for a quick code review of this function"

You: "Get GPT-5's opinion on this architectural decision with high verbosity"
```

Claude Code will automatically call the GPT-5 MCP server and return the results seamlessly.

### 🔧 Direct Tool Usage (Advanced)

For developers who want direct control, you can also use the tools explicitly:

```javascript
// Simple GPT-5 query
gpt5_query({
  "prompt": "Explain quantum computing in simple terms"
})

// Advanced query with context
gpt5_query({
  "prompt": "How can I optimize this React component?",
  "context": "I have a component that renders a large list of items and it's causing performance issues...",
  "model": "gpt-5",
  "verbosity": "high",
  "reasoning_effort": "extended"
})

// Use different GPT-5 variants
gpt5_query({
  "prompt": "Quick code review of this function",
  "model": "gpt-5-mini",  // Faster, more cost-effective
  "verbosity": "low"
})
```

### 🎯 Usage Examples

**Code Review:**
```
"Use GPT-5 to review this Python function for best practices and security issues"
```

**Architecture Discussion:**
```
"Ask GPT-5 with extended reasoning effort about this microservices design"
```

**Quick Help:**
```
"GPT-5-nano: how do I fix this JavaScript error?"
```

**Creative Tasks:**
```
"Use GPT-5 with high temperature to brainstorm API naming conventions"
```

## 🛠️ Available Tools

### `gpt5_query`

Query GPT-5 with Claude's original prompt and context.

**Parameters:**
- `prompt` (required): The main question or prompt
- `context` (optional): Additional context or conversation history  
- `model` (optional): GPT-5 variant (`gpt-5`, `gpt-5-mini`, `gpt-5-nano`)
- `verbosity` (optional): Response length (`low`, `medium`, `high`)
- `reasoning_effort` (optional): Thinking depth (`minimal`, `standard`, `extended`)
- `max_tokens` (optional): Maximum response length (1-128000)
- `temperature` (optional): Creativity level (0-2)

### `gpt5_test_connection`

Test your connection to the OpenAI GPT-5 API.

```javascript
gpt5_test_connection({})
```

## 🏗️ Architecture

```
Claude Code → MCP Protocol → GPT-5 MCP Server → OpenAI API → GPT-5
     ↑                                                          ↓
User Request                                        Response Processing
     ↑                                                          ↓
Formatted Response ← Message Processor ← GPT-5 Client ← Raw Response
```

### Components

- **MCP Server**: Implements the Model Context Protocol for Claude Code integration
- **GPT-5 Client**: Handles OpenAI API communication with authentication and retries
- **Message Processor**: Converts between Claude and GPT-5 message formats
- **Configuration Manager**: Manages API keys, settings, and environment variables

## 🧪 Testing

### 🔍 Health Check

Run the comprehensive health check to verify your installation:

```bash
# Run health check script
./bin/test.sh

# Or from project root
cd gpt5_mcp && ./bin/test.sh
```

**Health check includes:**
- ✅ Build artifacts exist
- ✅ Environment file configured
- ✅ API key validation
- ✅ Dependencies installed
- ✅ MCP server registration
- ✅ Server startup test

### 🧪 Manual Testing

```bash
# Test the server directly
cd gpt5_mcp
node dist/server.js

# Development mode with hot reload
npm run dev

# Test connection in Claude Code
# Use: gpt5_test_connection({})
```

### 🧪 Automated Test Suite

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test types
npm run test:unit
npm run test:integration
```

## 📁 Project Structure

```
gpt5-claude-mcp/
├── 📄 README.md              # This documentation
├── 📄 package.json           # Node.js dependencies and scripts
├── 🔧 install.sh             # One-click installation script
├── ⚙️ config/
│   ├── default.json          # Default configuration
│   └── example.env           # Environment template
├── 📂 src/
│   ├── server.ts             # Main MCP server
│   ├── gpt5-client.ts        # OpenAI API integration
│   ├── message-processor.ts  # Message format conversion
│   ├── config.ts             # Configuration management
│   └── types.ts              # TypeScript definitions
├── 🧪 tests/
│   ├── unit/                 # Unit tests
│   └── integration/          # Integration tests
├── 📖 docs/
│   ├── setup.md             # Detailed setup guide
│   ├── usage.md             # Usage examples
│   └── troubleshooting.md   # Common issues and solutions
└── 🛠️ scripts/
    ├── build.sh             # Build script
    └── validate-setup.sh    # Setup validation
```

## 🔧 Development

### Prerequisites

- **Node.js 18+**
- **npm or yarn**
- **OpenAI API key**
- **Claude Code** (for integration testing)

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/youbin2014/gpt5_mcp.git
cd gpt5_mcp

# Install dependencies
npm install

# Set up environment
cp config/example.env .env
# Edit .env with your API key

# Build and watch for changes
npm run dev
```

### Available Scripts

- `npm run build` - Build TypeScript to JavaScript
- `npm run dev` - Development mode with hot reload
- `npm start` - Start the production server
- `npm test` - Run test suite
- `npm run lint` - Lint TypeScript code
- `npm run format` - Format code with Prettier

## 📊 Performance

### Token Usage

The server efficiently manages token usage by:
- Truncating overly long prompts to prevent API limits
- Estimating token counts before requests
- Providing usage statistics in responses

### Caching

- Configuration caching for improved startup times
- Response format optimization
- Error handling with intelligent retries

## 🆘 Troubleshooting

### 🔧 Quick Fixes

First, run the health check to identify issues:
```bash
cd gpt5_mcp && ./bin/test.sh
```

### 🚨 Common Issues

#### ❌ "OpenAI API key is missing or invalid"

**Cause**: API key not configured or has incorrect format

**Solutions**:
1. **Check your .env file**: `cat gpt5_mcp/.env`
2. **Verify API key format**: Must start with `sk-`
3. **Get a new key**: Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
4. **Update .env file**:
   ```env
   OPENAI_API_KEY=sk-your-actual-api-key-here
   ```
5. **Re-register with key injection**:
   ```bash
   claude mcp add --scope user gpt5-claude-mcp --env OPENAI_API_KEY='sk-your-key' -- node 'gpt5_mcp/dist/server.js'
   ```

#### ❌ "gpt5_query tool not found" in Claude Code

**Cause**: MCP server not properly registered

**Solutions**:
1. **Check registration**: `claude mcp list`
2. **Look for**: `gpt5-claude-mcp` in the output
3. **Re-register manually**:
   ```bash
   cd gpt5_mcp
   claude mcp add --scope user gpt5-claude-mcp -- node "$(pwd)/dist/server.js"
   ```
4. **Restart Claude Code completely**

#### ❌ Connection timeout errors

**Cause**: Network issues or API key problems

**Solutions**:
1. **Test API key**: Run `./bin/test.sh`
2. **Check internet connection**
3. **Increase timeout in .env**:
   ```env
   OPENAI_TIMEOUT=120000
   ```
4. **Try different model**:
   ```env
   GPT5_DEFAULT_MODEL=gpt-5-mini
   ```

#### ❌ "Command not found: claude"

**Cause**: Claude Code CLI not installed

**Solution**: Install Claude Code:
```bash
# Follow the official installation guide:
# https://docs.anthropic.com/en/docs/claude-code
```

#### ❌ Build or installation failures

**Cause**: Missing dependencies or wrong Node.js version

**Solutions**:
1. **Check Node.js version**: `node -v` (requires 18+)
2. **Clean install**:
   ```bash
   cd gpt5_mcp
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```
3. **Reinstall completely**: Delete `gpt5_mcp/` and run installation script again

### 🔍 Debug Mode

Enable verbose logging for detailed troubleshooting:

```env
# Add to gpt5_mcp/.env
LOG_LEVEL=debug
LOG_REQUESTS=true
LOG_RESPONSES=true
```

Then restart the MCP server and check Claude Code console output.

### 🛠️ Manual Recovery

If automatic installation fails, try manual recovery:

```bash
# 1. Clean up existing registration
claude mcp remove gpt5-claude-mcp 2>/dev/null || true
claude mcp remove --scope user gpt5-claude-mcp 2>/dev/null || true

# 2. Rebuild from scratch
cd gpt5_mcp
npm run build

# 3. Manual registration with explicit paths
claude mcp add --scope user gpt5-claude-mcp \
  --env OPENAI_API_KEY='your-api-key-here' \
  -- node "$(pwd)/dist/server.js"

# 4. Verify registration
claude mcp list | grep gpt5-claude-mcp
```

### 🏥 Getting Help

1. **🔍 Health Check**: Always start with `./bin/test.sh`
2. **📖 Documentation**: Check `docs/troubleshooting.md` for detailed guides
3. **🔧 Manual Test**: Try `gpt5_test_connection({})` in Claude Code
4. **💬 Issues**: Report bugs on [GitHub Issues](https://github.com/youbin2014/gpt5_mcp/issues)
5. **📋 Include**: When reporting issues, include:
   - Output of `./bin/test.sh`
   - Your operating system
   - Node.js version (`node -v`)
   - Error messages from Claude Code console

### 🔄 Complete Reinstallation

If all else fails, start fresh:

```bash
# Remove everything
rm -rf gpt5_mcp/
claude mcp remove --scope user gpt5-claude-mcp 2>/dev/null || true

# Reinstall from scratch
curl -fsSL https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh | bash
```

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Guidelines

- Follow TypeScript best practices
- Add JSDoc comments for public APIs
- Include tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Anthropic** for Claude Code and the Model Context Protocol
- **OpenAI** for GPT-5 and the API
- **TypeScript Community** for excellent tooling and ecosystem

## 🔗 Related Projects

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [OpenAI API Documentation](https://platform.openai.com/docs)

---

**Made with ❤️ for the Claude Code community**

*Get started in minutes with GPT-5 integration! 🚀*