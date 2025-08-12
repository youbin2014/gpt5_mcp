#!/bin/bash

# GPT-5 Claude MCP - Build Script
# Compiles TypeScript and prepares the project for production

set -e

echo "🏗️  Building GPT-5 Claude MCP Server..."

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf dist/

# Check TypeScript compilation
echo "🔍 Checking TypeScript..."
npx tsc --noEmit

# Compile TypeScript
echo "📦 Compiling TypeScript..."
npx tsc

# Verify build output
echo "✅ Verifying build output..."
if [ ! -f "dist/server.js" ]; then
    echo "❌ Build failed: server.js not found"
    exit 1
fi

if [ ! -f "dist/gpt5-client.js" ]; then
    echo "❌ Build failed: gpt5-client.js not found"
    exit 1
fi

if [ ! -f "dist/message-processor.js" ]; then
    echo "❌ Build failed: message-processor.js not found"
    exit 1
fi

if [ ! -f "dist/config.js" ]; then
    echo "❌ Build failed: config.js not found"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 Output directory: dist/"
echo "🚀 Ready to run: node dist/server.js"