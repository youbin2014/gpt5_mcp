#!/bin/bash
# MCP setup script for this installation
echo "🔧 Setting up GPT-5 MCP for this project..."
claude mcp remove gpt5-claude-mcp 2>/dev/null || true
claude mcp add gpt5-claude-mcp "node $(dirname $0)/dist/server.js"
echo "✅ GPT-5 MCP server configured for this project"
