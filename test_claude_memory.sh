#!/bin/bash

# Test script for Claude Code + Mem0 integration
# This script helps validate the memory integration

set -e

echo "=================================="
echo "Claude Code + Mem0 Validation Test"
echo "=================================="
echo ""

# Load environment
echo "📋 Step 1: Loading environment variables..."
cd /Users/ankur/D/Playground/mem0
source .env

# Verify env
echo "✓ API Key: ${MEM0_API_KEY:0:10}..."
echo "✓ User ID: $MEM0_DEFAULT_USER_ID"
echo ""

# Check Claude Code
echo "📋 Step 2: Verifying Claude Code..."
if ! command -v claude &> /dev/null; then
    echo "❌ Claude Code not found. Please install it first."
    exit 1
fi
echo "✓ Claude Code version: $(claude --version)"
echo ""

# Check MCP config
echo "📋 Step 3: Verifying MCP configuration..."
if [ ! -f ~/.mcp.json ]; then
    echo "❌ ~/.mcp.json not found!"
    exit 1
fi
echo "✓ MCP config exists"

# Validate JSON
if ! cat ~/.mcp.json | python3 -m json.tool > /dev/null 2>&1; then
    echo "❌ Invalid JSON in ~/.mcp.json"
    exit 1
fi
echo "✓ MCP config is valid JSON"
echo ""

# Test MCP server
echo "📋 Step 4: Testing MCP server..."
if uvx mem0-mcp-server --help > /dev/null 2>&1; then
    echo "✓ MCP server is accessible"
else
    echo "❌ MCP server failed to start"
    exit 1
fi
echo ""

echo "=================================="
echo "✅ Pre-flight checks PASSED!"
echo "=================================="
echo ""
echo "📝 NEXT STEPS:"
echo ""
echo "1. Open a new terminal"
echo "2. Run: source /Users/ankur/D/Playground/mem0/.env"
echo "3. Run: claude"
echo "4. Test with: 'Please add a memory that I prefer TypeScript. Use add_memory tool.'"
echo "5. Check dashboard: https://app.mem0.ai"
echo ""
echo "After testing in Claude Code, verify:"
echo "  ☐ Memory add works"
echo "  ☐ Memory appears in dashboard"
echo "  ☐ Memory search works"
echo "  ☐ Memory persists across sessions"
echo ""

