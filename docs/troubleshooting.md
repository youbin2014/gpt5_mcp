# 🆘 Troubleshooting Guide

Common issues and solutions for the GPT-5 Claude MCP Server.

## 🔧 Installation Issues

### Node.js Version Issues

**Problem**: "Node.js version X.X.X is too old"

**Solution**:
```bash
# Update Node.js to version 18 or higher
# Using nvm (recommended)
nvm install 18
nvm use 18

# Or download from nodejs.org
```

**Problem**: "npm is not installed"

**Solution**:
```bash
# npm comes with Node.js, reinstall Node.js
# Or install npm separately
curl -L https://www.npmjs.com/install.sh | sh
```

### Permission Issues

**Problem**: "Permission denied" during installation

**Solution**:
```bash
# Don't use sudo with npm, fix permissions instead
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules

# Or use a Node version manager like nvm
```

### Claude Code Not Found

**Problem**: "Claude Code CLI not found in PATH"

**Solution**:
1. Install Claude Code from [official docs](https://docs.anthropic.com/en/docs/claude-code)
2. Add to PATH:
   ```bash
   export PATH="$PATH:/path/to/claude-code"
   ```
3. Restart terminal and try again

## ⚙️ Configuration Issues

### API Key Problems

**Problem**: "OpenAI API key is required"

**Solutions**:
1. Check `.env` file exists:
   ```bash
   ls -la .env
   ```
2. Verify API key format:
   ```env
   OPENAI_API_KEY=sk-your-actual-key-here
   ```
3. Ensure no extra spaces or quotes:
   ```env
   # ❌ Wrong
   OPENAI_API_KEY="sk-key"
   OPENAI_API_KEY= sk-key
   
   # ✅ Correct
   OPENAI_API_KEY=sk-key
   ```

**Problem**: "OpenAI API key appears to be invalid"

**Solutions**:
1. Verify key starts with `sk-`
2. Check key hasn't expired on [OpenAI Platform](https://platform.openai.com/api-keys)
3. Test key with curl:
   ```bash
   curl -H "Authorization: Bearer $OPENAI_API_KEY" \
        https://api.openai.com/v1/models
   ```

### Environment Loading Issues

**Problem**: Environment variables not loading

**Solutions**:
1. Ensure `.env` file is in project root
2. Check file permissions:
   ```bash
   chmod 644 .env
   ```
3. Restart the server after changes
4. Debug with:
   ```bash
   node -e "require('dotenv').config(); console.log(process.env.OPENAI_API_KEY)"
   ```

## 🚀 Runtime Issues

### Connection Problems

**Problem**: "Failed to connect to OpenAI API"

**Solutions**:
1. Test internet connectivity
2. Check firewall settings
3. Verify OpenAI service status at [status.openai.com](https://status.openai.com)
4. Try with curl:
   ```bash
   curl -i https://api.openai.com/v1/models \
        -H "Authorization: Bearer $OPENAI_API_KEY"
   ```

**Problem**: "Request timeout"

**Solutions**:
1. Increase timeout in `.env`:
   ```env
   OPENAI_TIMEOUT=120000
   ```
2. Check network stability
3. Try smaller prompts first

### Token Limit Issues

**Problem**: "Token limit exceeded"

**Solutions**:
1. Reduce prompt length
2. Use smaller model:
   ```javascript
   gpt5_query({
     "prompt": "your prompt",
     "model": "gpt-5-nano"  // Smaller context window
   })
   ```
3. Set max_tokens:
   ```javascript
   gpt5_query({
     "prompt": "your prompt",
     "max_tokens": 1000
   })
   ```

### Rate Limiting

**Problem**: "Rate limit exceeded"

**Solutions**:
1. Add delays between requests
2. Check your OpenAI usage limits
3. Upgrade OpenAI plan if needed
4. Implement request queuing:
   ```env
   MAX_RETRIES=5
   RETRY_DELAY=2000
   ```

## 🔧 MCP Integration Issues

### Tool Not Found

**Problem**: "'gpt5_query' tool not found in Claude Code"

**Solutions**:
1. Verify MCP server is added:
   ```bash
   claude mcp list
   ```
2. Re-add the server:
   ```bash
   claude mcp remove gpt5-claude-mcp
   claude mcp add gpt5-claude-mcp "node $(pwd)/dist/server.js"
   ```
3. Restart Claude Code
4. Check server path is correct:
   ```bash
   ls -la dist/server.js
   ```

### Server Not Starting

**Problem**: MCP server fails to start

**Solutions**:
1. Check build completed:
   ```bash
   npm run build
   ls -la dist/
   ```
2. Test server manually:
   ```bash
   node dist/server.js
   ```
3. Check for syntax errors:
   ```bash
   npm run lint
   ```
4. Review console output for specific errors

### Communication Issues

**Problem**: MCP communication failures

**Solutions**:
1. Check stdio communication:
   ```bash
   echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | node dist/server.js
   ```
2. Verify JSON-RPC format
3. Check for console.log interference (remove all stdout writes)
4. Test with simple request first

## 📊 Performance Issues

### Slow Responses

**Problem**: GPT-5 queries are slow

**Solutions**:
1. Use faster models:
   ```javascript
   gpt5_query({
     "prompt": "your prompt",
     "model": "gpt-5-mini",        // Faster
     "reasoning_effort": "minimal"  // Less thinking time
   })
   ```
2. Reduce verbosity:
   ```javascript
   gpt5_query({
     "prompt": "your prompt",
     "verbosity": "low"
   })
   ```
3. Optimize prompts (shorter, more specific)

### Memory Issues

**Problem**: High memory usage

**Solutions**:
1. Limit concurrent requests
2. Reduce context size
3. Clear unused variables
4. Monitor with:
   ```bash
   node --max-old-space-size=4096 dist/server.js
   ```

## 🐛 Debugging

### Enable Debug Mode

```env
# Add to .env file
LOG_LEVEL=debug
LOG_REQUESTS=true
LOG_RESPONSES=true
```

### Server Debugging

```bash
# Start with debugging
npm run dev

# Or with Node debugging
node --inspect dist/server.js

# Check server status
./test.sh
```

### Request/Response Debugging

```javascript
// Test with minimal request
gpt5_query({
  "prompt": "Hello",
  "model": "gpt-5-nano",
  "verbosity": "low",
  "max_tokens": 10
})
```

### Network Debugging

```bash
# Test OpenAI connectivity
curl -v -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models

# Check DNS resolution
nslookup api.openai.com

# Test with proxy if needed
export https_proxy=http://proxy:port
```

## 🔍 Common Error Messages

### "Module not found"

**Cause**: Missing dependencies or incorrect import paths

**Solution**:
```bash
npm install
npm run build
```

### "Permission denied"

**Cause**: File permission issues

**Solution**:
```bash
chmod +x install.sh
chmod 644 .env
```

### "ECONNREFUSED"

**Cause**: Network connectivity issues

**Solution**:
1. Check internet connection
2. Verify firewall settings
3. Test with different network

### "Invalid JSON"

**Cause**: Malformed MCP request/response

**Solution**:
1. Check for console.log in server code
2. Verify JSON syntax
3. Test with simple request

## 📋 Diagnostic Checklist

When troubleshooting, check these items:

### ✅ Environment Setup
- [ ] Node.js 18+ installed
- [ ] npm working correctly
- [ ] Project dependencies installed (`npm install`)
- [ ] TypeScript compiled (`npm run build`)
- [ ] `.env` file exists with API key

### ✅ OpenAI Configuration
- [ ] API key is valid and starts with `sk-`
- [ ] API key has sufficient credits
- [ ] Network can reach `api.openai.com`
- [ ] Rate limits not exceeded

### ✅ MCP Integration
- [ ] Claude Code is installed
- [ ] MCP server is added to Claude Code
- [ ] Server builds without errors
- [ ] Server starts without errors

### ✅ Functionality
- [ ] Connection test passes (`./test.sh`)
- [ ] Simple query works
- [ ] Error handling works correctly

## 🆘 Getting Help

If you're still having issues:

1. **Check Logs**: Review console output for specific error messages
2. **Test Connection**: Run `./test.sh` to verify setup
3. **Minimal Reproduction**: Try the simplest possible query
4. **GitHub Issues**: Search existing issues or create a new one
5. **Documentation**: Review all documentation in the `docs/` folder

### Creating a Bug Report

Include this information:

```
**Environment:**
- OS: [macOS/Linux/Windows]
- Node.js version: [version]
- npm version: [version]
- Claude Code version: [version]

**Configuration:**
- GPT-5 model: [gpt-5/gpt-5-mini/gpt-5-nano]
- Environment variables: [relevant ones, NO API KEY]

**Error:**
[Full error message and stack trace]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [And so on...]

**Expected vs Actual:**
Expected: [what you expected]
Actual: [what happened]
```

Remember to **never include your actual API key** in bug reports!