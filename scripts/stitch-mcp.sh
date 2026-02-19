#!/bin/bash
# Stitch MCP Interaction Script
# Usage: ./scripts/stitch-mcp.sh <command> [args]
#
# Commands:
#   list-tools          - List available MCP tools
#   call <tool> <json>  - Call a tool with JSON arguments
#   get-project <id>    - Get project details
#   list-screens <id>   - List screens in a project
#   export-code <id>    - Export code from a project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/.stitch/mcp-config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

MCP_URL=$(jq -r '.mcp.stitch.url' "$CONFIG_FILE")
API_KEY=$(jq -r '.mcp.stitch.headers["X-Goog-Api-Key"]' "$CONFIG_FILE")

# JSON-RPC request counter
REQUEST_ID=1

# Send a JSON-RPC request to the MCP server
send_request() {
    local method="$1"
    local params="$2"
    
    local payload=$(cat <<EOF
{
    "jsonrpc": "2.0",
    "id": $REQUEST_ID,
    "method": "$method",
    "params": $params
}
EOF
)
    
    REQUEST_ID=$((REQUEST_ID + 1))
    
    curl -s -X POST "$MCP_URL" \
        -H "Content-Type: application/json" \
        -H "X-Goog-Api-Key: $API_KEY" \
        -d "$payload"
}

# Initialize the MCP connection
initialize() {
    echo "Initializing MCP connection..."
    send_request "initialize" '{
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {
            "name": "fspec-mobile-stitch",
            "version": "1.0.0"
        }
    }' | jq .
}

# List available tools
list_tools() {
    echo "Listing available tools..."
    send_request "tools/list" '{}' | jq .
}

# Call a specific tool
call_tool() {
    local tool_name="$1"
    local arguments="$2"
    
    if [[ -z "$tool_name" ]]; then
        echo "Error: Tool name required"
        echo "Usage: $0 call <tool_name> '<json_arguments>'"
        exit 1
    fi
    
    echo "Calling tool: $tool_name"
    send_request "tools/call" "{
        \"name\": \"$tool_name\",
        \"arguments\": $arguments
    }" | jq .
}

# Get project details
get_project() {
    local project_id="$1"
    
    if [[ -z "$project_id" ]]; then
        echo "Error: Project ID required"
        exit 1
    fi
    
    call_tool "get_project" "{\"projectId\": \"$project_id\"}"
}

# List screens in a project
list_screens() {
    local project_id="$1"
    
    if [[ -z "$project_id" ]]; then
        echo "Error: Project ID required"
        exit 1
    fi
    
    call_tool "list_screens" "{\"projectId\": \"$project_id\"}"
}

# Export code from a project
export_code() {
    local project_id="$1"
    local format="${2:-react}"
    
    if [[ -z "$project_id" ]]; then
        echo "Error: Project ID required"
        exit 1
    fi
    
    call_tool "export_code" "{\"projectId\": \"$project_id\", \"format\": \"$format\"}"
}

# Main command dispatcher
case "${1:-help}" in
    init|initialize)
        initialize
        ;;
    list-tools|tools)
        list_tools
        ;;
    call)
        call_tool "$2" "${3:-{}}"
        ;;
    get-project)
        get_project "$2"
        ;;
    list-screens)
        list_screens "$2"
        ;;
    export-code)
        export_code "$2" "$3"
        ;;
    help|--help|-h)
        echo "Stitch MCP Interaction Script"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init                    - Initialize MCP connection"
        echo "  list-tools              - List available MCP tools"
        echo "  call <tool> <json>      - Call a tool with JSON arguments"
        echo "  get-project <id>        - Get project details"
        echo "  list-screens <id>       - List screens in a project"
        echo "  export-code <id> [fmt]  - Export code (format: react|html)"
        echo ""
        echo "Example:"
        echo "  $0 init"
        echo "  $0 list-tools"
        echo "  $0 get-project 3043192573872517229"
        echo "  $0 export-code 3043192573872517229 react"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
