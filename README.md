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

### Option 1: One-Click Installation (Recommended)

Install directly in your current project directory:

```bash
# Automatic installation to current directory
curl -fsSL https://raw.githubusercontent.com/youbin2014/gpt5_mcp/main/install.sh | bash
```

### Option 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/youbin2014/gpt5_mcp.git
cd gpt5_mcp

# Run installation script
./install.sh
```

### Option 3: Development Setup

```bash
# Clone repository
git clone https://github.com/youbin2014/gpt5_mcp.git
cd gpt5_mcp

# Install dependencies
npm install

# Set up environment
cp config/example.env .env
# Edit .env file with your OpenAI API key

# Build project
npm run build

# Add to Claude Code
claude mcp add gpt5-claude-mcp "node $(pwd)/dist/server.js"
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

### Test Connection

```bash
# Test your OpenAI API connection
./test.sh
```

### Manual Testing

```bash
# Start the server manually for debugging
npm run dev

# Or start the built version
npm start
```

### Run Test Suite

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage
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

### Common Issues

#### "OpenAI API key is required" Error

**Solution**: Make sure your `.env` file contains a valid OpenAI API key:
```env
OPENAI_API_KEY=sk-your-actual-api-key-here
```

#### "gpt5_query tool not found" in Claude Code

**Solutions**:
1. Verify MCP server is added: `claude mcp list`
2. Re-add the server: `claude mcp add gpt5-claude-mcp "node /path/to/dist/server.js"`
3. Restart Claude Code

#### Connection timeout errors

**Solutions**:
1. Check your internet connection
2. Verify OpenAI API key is valid
3. Increase timeout in `.env`: `OPENAI_TIMEOUT=120000`

#### "Command not found: claude"

**Solution**: Install Claude Code CLI:
```bash
# Follow instructions at:
https://docs.anthropic.com/en/docs/claude-code
```

### Debug Mode

Enable debug logging for troubleshooting:

```env
LOG_LEVEL=debug
LOG_REQUESTS=true
LOG_RESPONSES=true
```

### Getting Help

1. **Check Documentation**: Review `docs/troubleshooting.md`
2. **Test Connection**: Run `./test.sh` to verify setup
3. **View Logs**: Check console output when running Claude Code
4. **GitHub Issues**: Report bugs or request features

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