#!/bin/bash

#################################################################
# Mem0 + Claude Code Integration Setup Script
# Interactive, guided setup with beautiful terminal UI
#################################################################

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"
ROCKET="🚀"
BRAIN="🧠"
LOCK="🔐"
GEAR="⚙️"
MAGNIFY="🔍"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#################################################################
# Helper Functions
#################################################################

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}${BOLD}▶ Step $1:${NC} ${WHITE}$2${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

print_action() {
    echo -e "${PURPLE}${ARROW}${NC} $1"
}

ask_question() {
    echo -e "${YELLOW}?${NC} ${BOLD}$1${NC}"
}

wait_for_enter() {
    echo ""
    echo -e "${DIM}Press Enter to continue...${NC}"
    read
}

confirm_action() {
    while true; do
        echo -e "${YELLOW}?${NC} ${BOLD}$1 (y/n):${NC} \c"
        read -r yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Please answer yes (y) or no (n).${NC}";;
        esac
    done
}

#################################################################
# Main Setup Functions
#################################################################

show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║        🧠  Mem0 + Claude Code Integration  🚀        ║
    ║                                                       ║
    ║     Persistent Memory Across All Your Devices        ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${DIM}                  Interactive Setup Wizard${NC}"
    echo ""
    wait_for_enter
}

check_prerequisites() {
    print_header "Prerequisites Check"
    print_step "1" "Verifying system requirements"
    
    local all_good=true
    
    # Check OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_success "macOS detected"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_success "Linux detected"
    else
        print_warning "Unsupported OS: $OSTYPE (may still work)"
    fi
    
    # Check Claude Code
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>&1 | head -n1)
        print_success "Claude Code installed: $CLAUDE_VERSION"
    else
        print_error "Claude Code not found"
        print_info "Install from: ${CYAN}https://code.claude.com${NC}"
        all_good=false
    fi
    
    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        print_success "$PYTHON_VERSION"
    else
        print_error "Python 3 not found"
        all_good=false
    fi
    
    # Check uv/uvx
    if command -v uvx &> /dev/null; then
        UV_VERSION=$(uv --version 2>&1)
        print_success "uv installed: $UV_VERSION"
    else
        print_warning "uv not found"
        if confirm_action "Would you like to install uv now?"; then
            print_action "Installing uv..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install uv
            else
                curl -LsSf https://astral.sh/uv/install.sh | sh
            fi
            print_success "uv installed successfully"
        else
            print_error "uv is required for this integration"
            all_good=false
        fi
    fi
    
    echo ""
    
    if [ "$all_good" = false ]; then
        print_error "Some prerequisites are missing. Please install them and run setup again."
        exit 1
    fi
    
    print_success "All prerequisites satisfied!"
    wait_for_enter
}

setup_mem0_account() {
    print_header "Mem0 Platform Setup"
    print_step "2" "Setting up your Mem0 account"
    
    print_info "You need a Mem0 Platform account to continue."
    echo ""
    
    if confirm_action "Do you have a Mem0 account?"; then
        print_success "Great! Let's continue..."
    else
        print_action "Opening Mem0 signup page..."
        echo ""
        echo -e "   ${CYAN}https://app.mem0.ai${NC}"
        echo ""
        print_info "Please:"
        echo "   1. Sign up for a free account"
        echo "   2. Verify your email"
        echo "   3. Come back here when ready"
        echo ""
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "https://app.mem0.ai" 2>/dev/null || true
        fi
        
        wait_for_enter
    fi
}

get_api_key() {
    print_header "API Key Configuration"
    print_step "3" "Getting your Mem0 API key"
    
    echo -e "   ${CYAN}https://app.mem0.ai/settings/api-keys${NC}"
    echo ""
    print_info "Steps to get your API key:"
    echo "   1. Log in to Mem0 Platform"
    echo "   2. Go to Settings → API Keys"
    echo "   3. Create a new API key"
    echo "   4. Copy the key (starts with 'm0-')"
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if confirm_action "Open API keys page in browser?"; then
            open "https://app.mem0.ai/settings/api-keys" 2>/dev/null || true
        fi
    fi
    
    echo ""
    ask_question "Paste your Mem0 API key here:"
    read -r MEM0_API_KEY
    
    # Validate API key format
    if [[ ! "$MEM0_API_KEY" =~ ^m0- ]]; then
        print_warning "API key should start with 'm0-'"
        if ! confirm_action "Continue anyway?"; then
            get_api_key
            return
        fi
    fi
    
    print_success "API key saved"
    echo ""
}

get_user_id() {
    print_header "User ID Configuration"
    print_step "4" "Setting your user identifier"
    
    print_info "This ID identifies YOU across all devices."
    print_info "Use the same ID on all your machines for memory sync."
    echo ""
    print_info "Suggestions:"
    echo "   • Your email address"
    echo "   • Your GitHub username"
    echo "   • Any unique identifier"
    echo ""
    
    ask_question "Enter your user ID:"
    read -r MEM0_USER_ID
    
    if [ -z "$MEM0_USER_ID" ]; then
        print_error "User ID cannot be empty"
        get_user_id
        return
    fi
    
    print_success "User ID set to: ${GREEN}$MEM0_USER_ID${NC}"
    echo ""
    print_warning "IMPORTANT: Use '${GREEN}$MEM0_USER_ID${NC}' on all your devices!"
    wait_for_enter
}

create_env_file() {
    print_header "Environment Configuration"
    print_step "5" "Creating .env file"
    
    ENV_FILE="$SCRIPT_DIR/.env"
    
    print_action "Writing configuration to .env..."
    
    cat > "$ENV_FILE" << EOF
# Mem0 + Claude Code Integration
# Generated: $(date)

# Mem0 API Key (from https://app.mem0.ai/settings/api-keys)
export MEM0_API_KEY="$MEM0_API_KEY"

# Your unique user identifier (use same on all devices)
export MEM0_DEFAULT_USER_ID="$MEM0_USER_ID"

# Graph memory (optional, experimental)
export MEM0_ENABLE_GRAPH_DEFAULT="false"

# LLM Model for MCP server
export MEM0_MCP_AGENT_MODEL="claude-3-5-sonnet-20241022"

# Optional: Add these if needed
# export OPENAI_API_KEY="sk-..."
# export ANTHROPIC_API_KEY="sk-..."
EOF
    
    chmod 600 "$ENV_FILE"
    print_success "Environment file created: ${GREEN}.env${NC}"
    print_success "File permissions set to 600 (secure)"
    
    # Load the environment
    source "$ENV_FILE"
    
    wait_for_enter
}

setup_mcp_config() {
    print_header "MCP Configuration"
    print_step "6" "Configuring Model Context Protocol"
    
    MCP_CONFIG="$HOME/.mcp.json"
    
    if [ -f "$MCP_CONFIG" ]; then
        print_warning "~/.mcp.json already exists"
        
        if grep -q '"mem0"' "$MCP_CONFIG" 2>/dev/null; then
            print_info "Mem0 configuration already present"
            if ! confirm_action "Update the configuration?"; then
                print_info "Skipping MCP configuration"
                wait_for_enter
                return
            fi
        fi
    fi
    
    print_action "Configuring MCP server..."
    
    # Create or update MCP config
    if [ ! -f "$MCP_CONFIG" ]; then
        cat > "$MCP_CONFIG" << 'EOF'
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
EOF
        print_success "Created ~/.mcp.json"
    else
        print_info "Updating existing ~/.mcp.json"
        # Use Python to merge JSON (more reliable)
        python3 << 'PYTHON_SCRIPT'
import json
import os

config_file = os.path.expanduser("~/.mcp.json")
with open(config_file, 'r') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['mem0'] = {
    "command": "uvx",
    "args": ["mem0-mcp-server"],
    "env": {
        "MEM0_API_KEY": "${MEM0_API_KEY}",
        "MEM0_DEFAULT_USER_ID": "${MEM0_DEFAULT_USER_ID}",
        "MEM0_ENABLE_GRAPH_DEFAULT": "${MEM0_ENABLE_GRAPH_DEFAULT:-false}"
    }
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print("Updated ~/.mcp.json with mem0 configuration")
PYTHON_SCRIPT
        print_success "Updated ~/.mcp.json"
    fi
    
    wait_for_enter
}

test_mcp_server() {
    print_header "MCP Server Test"
    print_step "7" "Testing mem0-mcp-server"
    
    print_action "Installing/verifying mem0-mcp-server..."
    
    if uvx mem0-mcp-server --help &> /dev/null; then
        print_success "MCP server is accessible"
    else
        print_error "Failed to access MCP server"
        print_info "This might resolve on first Claude Code launch"
    fi
    
    wait_for_enter
}

setup_shell_integration() {
    print_header "Shell Integration (Optional)"
    print_step "8" "Auto-load environment variables"
    
    print_info "Would you like to automatically load .env when starting a new shell?"
    echo ""
    
    if confirm_action "Add to shell profile?"; then
        SHELL_RC=""
        
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_RC="$HOME/.bashrc"
        fi
        
        if [ -n "$SHELL_RC" ]; then
            LOAD_LINE="source $SCRIPT_DIR/.env  # Mem0 + Claude Code"
            
            if grep -q "source.*mem0.*\.env" "$SHELL_RC" 2>/dev/null; then
                print_info "Already configured in $SHELL_RC"
            else
                echo "" >> "$SHELL_RC"
                echo "# Mem0 + Claude Code Integration" >> "$SHELL_RC"
                echo "$LOAD_LINE" >> "$SHELL_RC"
                print_success "Added to $SHELL_RC"
                print_info "Run: ${CYAN}source $SHELL_RC${NC} to apply"
            fi
        fi
    else
        print_info "Skipped. You can manually load with:"
        echo -e "   ${CYAN}source $SCRIPT_DIR/.env${NC}"
    fi
    
    wait_for_enter
}

run_validation() {
    print_header "Validation & Testing"
    print_step "9" "Running integration tests"
    
    print_action "Loading environment..."
    source "$SCRIPT_DIR/.env"
    
    print_action "Running validation script..."
    echo ""
    
    if [ -f "$SCRIPT_DIR/test_claude_memory.sh" ]; then
        bash "$SCRIPT_DIR/test_claude_memory.sh"
    else
        print_warning "test_claude_memory.sh not found"
        print_info "Performing basic validation..."
        
        # Basic checks
        if [ -n "$MEM0_API_KEY" ]; then
            print_success "Environment loaded correctly"
        else
            print_error "Failed to load environment"
        fi
    fi
    
    wait_for_enter
}

show_completion() {
    clear
    print_header "Setup Complete! 🎉"
    
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║            ✓  Setup Successful!  ✓                   ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${WHITE}${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Load your environment:"
    echo -e "   ${DIM}\$${NC} ${CYAN}source $SCRIPT_DIR/.env${NC}"
    echo ""
    echo -e "${CYAN}2.${NC} Test Claude Code with memory:"
    echo -e "   ${DIM}\$${NC} ${CYAN}claude --print \"Remember that I prefer TypeScript\"${NC}"
    echo ""
    echo -e "${CYAN}3.${NC} Verify memory recall:"
    echo -e "   ${DIM}\$${NC} ${CYAN}claude --print \"What programming languages do I prefer?\"${NC}"
    echo ""
    echo -e "${CYAN}4.${NC} Check your memories:"
    echo -e "   ${DIM}→${NC} ${CYAN}https://app.mem0.ai${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}For Other Devices:${NC}"
    echo ""
    echo -e "   ${DIM}1.${NC} Install Claude Code and uv"
    echo -e "   ${DIM}2.${NC} Copy your ${GREEN}.env${NC} file"
    echo -e "   ${DIM}3.${NC} Run this setup script again"
    echo -e "   ${DIM}4.${NC} Use the ${GREEN}same${NC} user ID: ${GREEN}$MEM0_USER_ID${NC}"
    echo ""
    
    echo -e "${DIM}════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Documentation:${NC} ${CYAN}README.md${NC}"
    echo -e "${WHITE}Architecture:${NC} ${CYAN}LLD.md${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

#################################################################
# Main Execution
#################################################################

main() {
    show_banner
    check_prerequisites
    setup_mem0_account
    get_api_key
    get_user_id
    create_env_file
    setup_mcp_config
    test_mcp_server
    setup_shell_integration
    run_validation
    show_completion
}

# Run main function
main

