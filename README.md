# Mem0 + Claude Code Integration

> Persistent, cross-device memory layer for Claude Code using Mem0 Platform

## Overview

This project integrates [Mem0 Platform](https://mem0.ai) with [Claude Code](https://code.claude.com) to provide intelligent, persistent memory across all your devices. Claude Code will remember your coding preferences, project context, and past decisions automatically.

## Features

- 🧠 **Persistent Memory** - Remembers across sessions and devices
- 🔄 **Cross-Device Sync** - Same memory on laptop, desktop, and cloud VMs
- 🎯 **Context-Aware** - Automatically recalls relevant information
- 🔐 **Secure** - API keys managed via environment variables
- 📊 **Modular Design** - Clean separation of concerns

## Quick Start

### 🚀 Automated Setup (Recommended)

The easiest way to get started:

```bash
cd /Users/ankur/D/Playground/mem0
./setup.sh
```

The interactive setup wizard will guide you through:
- ✓ Prerequisites checking
- ✓ Mem0 account setup
- ✓ API key configuration
- ✓ Environment file creation
- ✓ MCP configuration
- ✓ Validation testing

**Features:**
- 🎨 Beautiful colored terminal UI
- 📋 Step-by-step guidance
- ✅ Automatic validation
- 🔒 Secure configuration

---

### Manual Setup (Alternative)

If you prefer manual setup:

#### Prerequisites

- Claude Code installed ([Install guide](https://code.claude.com/docs/en/overview))
- Python 3.10+ with `uv` package manager
- Mem0 Platform account ([Sign up](https://app.mem0.ai))

#### Setup Steps

1. **Clone and navigate to the repository**
   ```bash
   cd /Users/ankur/D/Playground/mem0
   ```

2. **Configure environment variables**
   ```bash
   # Copy the example file
   cp .env.example .env

   # Edit .env and add your credentials
   nano .env
   ```

   Update these values:
   ```bash
   export MEM0_API_KEY="m0-your-actual-api-key"
   export MEM0_DEFAULT_USER_ID="your-username"
   export MEM0_ENABLE_GRAPH_DEFAULT="false"
   ```

3. **Load environment variables**
   ```bash
   source .env
   ```

4. **Configure MCP for Claude Code**

   The `~/.mcp.json` file should already be configured. Verify it exists:
   ```bash
   cat ~/.mcp.json
   ```

5. **Test the integration**
   ```bash
   claude --print --dangerously-skip-permissions "Remember that I prefer TypeScript"
   ```

### Auto-load Environment (Optional)

Add to your shell profile to automatically load environment variables:

```bash
echo 'source /Users/ankur/D/Playground/mem0/.env' >> ~/.zshrc
source ~/.zshrc
```

## Architecture

See [LLD.md](LLD.md) for detailed architecture documentation including:
- System architecture diagrams
- Data flow sequences
- Modular code structure
- Security design
- Performance considerations

## Project Structure

```
mem0/
├── .env                      # Your config (git-ignored)
├── .env.example              # Template for .env
├── .gitignore                # Git ignore rules
├── setup.sh                  # 🚀 Interactive setup wizard
├── test_claude_memory.sh     # Validation script
├── README.md                 # This file
├── LLD.md                    # Low-level design document
├── VALIDATION_REPORT.md      # Test results
├── openmemory.md             # OpenMemory guide
└── claude-mem0.env.example   # Legacy template
```

## Usage Examples

### Personal Preferences

```bash
source .env
claude --print --dangerously-skip-permissions "Remember I prefer pytest over unittest"
```

Later:
```bash
claude --print --dangerously-skip-permissions "What's my Python testing preference?"
```

### Search Memories

```bash
claude --print --dangerously-skip-permissions "Search my memories for programming preferences"
```

## Configuration Files

### Environment Variables (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `MEM0_API_KEY` | Your Mem0 Platform API key | `m0-xxx...` |
| `MEM0_DEFAULT_USER_ID` | Your unique user identifier | `ankur@example.com` |
| `MEM0_ENABLE_GRAPH_DEFAULT` | Enable graph memory features | `false` |

### MCP Configuration (~/.mcp.json)

```json
{
  "mcpServers": {
    "mem0": {
      "command": "uvx",
      "args": ["mem0-mcp-server"],
      "env": {
        "MEM0_API_KEY": "${MEM0_API_KEY}",
        "MEM0_DEFAULT_USER_ID": "${MEM0_DEFAULT_USER_ID}",
        "MEM0_ENABLE_GRAPH_DEFAULT": "${MEM0_ENABLE_GRAPH_DEFAULT:-false}"
      }
    }
  }
}
```

## Cross-Device Setup

To use the same memory across multiple devices:

1. **Install Claude Code and UV** on each device
2. **Copy configuration files**:
   - `.env` (with your API key)
   - Ensure `~/.mcp.json` is configured
3. **Use the SAME `MEM0_DEFAULT_USER_ID`** on all devices
4. **Source the environment** before running Claude Code

All devices will automatically share the same memory!

## Troubleshooting

### "uvx command not found"

```bash
brew install uv  # macOS
# or
pip install uv
```

### "Claude Code doesn't recognize memory tools"

1. Verify `~/.mcp.json` exists and is valid JSON
2. Check that environment variables are loaded: `echo $MEM0_API_KEY`
3. Restart Claude Code completely

### "Invalid API key"

- Verify your API key in `.env`
- Generate a new key at [app.mem0.ai/settings/api-keys](https://app.mem0.ai/settings/api-keys)
- Ensure no extra spaces or quotes in the `.env` file

### Memory not syncing across devices

- Confirm you're using the **same** `MEM0_DEFAULT_USER_ID` on all devices
- Check the Mem0 dashboard to verify memories are being saved
- Ensure all devices have network access to Mem0 Platform

## Available Memory Tools

Claude Code has access to these MCP tools:

- `add_memory` - Save new information
- `search_memories` - Find relevant memories
- `get_memories` - List all memories
- `get_memory` - Retrieve specific memory by ID
- `update_memory` - Modify existing memory
- `delete_memory` - Remove specific memory
- `delete_all_memories` - Bulk delete
- `delete_entities` - Remove entity and its memories
- `list_entities` - View stored entities

## Security Best Practices

- ✅ Never commit `.env` files to git
- ✅ Rotate API keys regularly
- ✅ Use different `user_id` for different contexts if needed
- ✅ Review memories periodically in Mem0 dashboard
- ❌ Don't share your `.env` file
- ❌ Don't hardcode API keys in code
- ❌ Don't use the same API key for public projects

## Validation

Run the validation script to test your setup:

```bash
./test_claude_memory.sh
```

See [VALIDATION_REPORT.md](VALIDATION_REPORT.md) for detailed test results.

## Resources

- [Claude Code Documentation](https://code.claude.com/docs/en/overview)
- [Mem0 Platform](https://app.mem0.ai)
- [Mem0 Documentation](https://docs.mem0.ai)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [Low-Level Design Document](LLD.md)

## Contributing

This is a personal integration project. For contributions to:
- **Claude Code**: Visit [Claude Code docs](https://code.claude.com)
- **Mem0**: Visit [Mem0 GitHub](https://github.com/mem0ai/mem0)

## License

This integration setup is for personal use. Refer to:
- [Claude Code Terms](https://www.anthropic.com/legal/consumer-terms)
- [Mem0 Platform Terms](https://mem0.ai/terms)

---

**Last Updated:** January 7, 2026
**Status:** Validated & Production Ready ✅
