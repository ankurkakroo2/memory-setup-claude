# Low-Level Design: Mem0 + Claude Code Integration

## Overview

This document describes the low-level design for integrating Mem0 Platform with Claude Code to provide persistent, cross-device memory capabilities for AI-assisted coding workflows.

---

## System Architecture

### High-Level Component Diagram

```mermaid
graph TB
    subgraph UserLayer["User Layer"]
        User[Developer]
        Terminal[Terminal/Shell]
    end

    subgraph ClaudeCodeLayer["Claude Code Layer"]
        CC[Claude Code CLI]
        CCAgent[Claude Agent]
    end

    subgraph MCPLayer["MCP Protocol Layer"]
        MCPClient[MCP Client<br/>Built into Claude Code]
        MCPServer[MCP Server<br/>mem0-mcp-server]
    end

    subgraph ConfigLayer["Configuration Layer"]
        MCPConfig[~/.mcp.json]
        EnvFile[claude-mem0.env]
    end

    subgraph Mem0Layer["Mem0 Platform"]
        Mem0API[Mem0 REST API]
        MemStore[Memory Store]
        VectorDB[Vector Database]
        LLM[LLM Processing]
    end

    User -->|runs 'claude'| Terminal
    Terminal -->|sources| EnvFile
    Terminal -->|executes| CC
    CC -->|reads config| MCPConfig
    CC -->|spawns| CCAgent
    CCAgent -->|uses tools via| MCPClient
    MCPClient -->|stdio/SSE| MCPServer
    MCPServer -->|HTTP/REST| Mem0API
    Mem0API -->|stores/retrieves| MemStore
    MemStore -->|vector search| VectorDB
    MemStore -->|processes| LLM

    style UserLayer fill:#e1f5ff
    style ClaudeCodeLayer fill:#fff4e1
    style MCPLayer fill:#f0e1ff
    style ConfigLayer fill:#e1ffe1
    style Mem0Layer fill:#ffe1e1
```

---

## Data Flow

### Memory Add Operation Flow

```mermaid
sequenceDiagram
    actor User
    participant CC as Claude Code
    participant MCP as MCP Client
    participant Server as mem0-mcp-server
    participant Mem0 as Mem0 Platform API
    participant Store as Memory Store

    User->>CC: "Remember I prefer TypeScript"
    CC->>CC: Analyze request<br/>Decide to use add_memory tool
    CC->>MCP: Call add_memory tool
    MCP->>Server: add_memory(content, user_id)
    Server->>Server: Load env variables<br/>(API_KEY, USER_ID)
    Server->>Mem0: POST /v1/memories<br/>Authorization: Bearer {API_KEY}
    Mem0->>Mem0: Process with LLM<br/>Extract facts
    Mem0->>Store: Store memory<br/>+ embedding vector
    Store-->>Mem0: memory_id
    Mem0-->>Server: {memory_id, content, metadata}
    Server-->>MCP: Success response
    MCP-->>CC: Tool result
    CC-->>User: "I've saved your preference"
```

### Memory Search Operation Flow

```mermaid
sequenceDiagram
    actor User
    participant CC as Claude Code
    participant MCP as MCP Client
    participant Server as mem0-mcp-server
    participant Mem0 as Mem0 Platform API
    participant VectorDB as Vector Database

    User->>CC: "What are my coding preferences?"
    CC->>CC: Analyze query<br/>Decide to search memories
    CC->>MCP: Call search_memories tool
    MCP->>Server: search_memories(query, user_id)
    Server->>Mem0: POST /v1/memories/search<br/>query: "coding preferences"
    Mem0->>Mem0: Generate query embedding
    Mem0->>VectorDB: Vector similarity search
    VectorDB-->>Mem0: Top K similar memories
    Mem0->>Mem0: Re-rank results
    Mem0-->>Server: [{memory, score}, ...]
    Server-->>MCP: Search results
    MCP-->>CC: Tool result with memories
    CC->>CC: Synthesize response
    CC-->>User: "You prefer TypeScript..."
```

---

## Component Details

### 1. Configuration Layer

#### File: `~/.mcp.json`
**Purpose:** MCP server configuration for Claude Code

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

**Responsibilities:**
- Define MCP server command and arguments
- Reference environment variables (not hardcode secrets)
- Configure server behavior via env vars

#### File: `claude-mem0.env`
**Purpose:** Environment variable definitions

```bash
export MEM0_API_KEY="m0-..."
export MEM0_DEFAULT_USER_ID="username"
export MEM0_ENABLE_GRAPH_DEFAULT="false"
```

**Responsibilities:**
- Store sensitive credentials (API keys)
- Define user identity for memory scope
- Configure feature flags

**Security:**
- Git-ignored to prevent credential leakage
- Sourced before Claude Code execution
- Single source of truth for credentials

---

### 2. MCP Protocol Layer

#### MCP Client (Built into Claude Code)
**Responsibilities:**
- Discover available MCP servers from config
- Spawn MCP server processes
- Communicate via stdio/SSE protocol
- Expose tools to Claude Agent
- Handle tool invocations

**Protocol:** Model Context Protocol (MCP)
- Transport: stdio or Server-Sent Events (SSE)
- Message format: JSON-RPC 2.0

#### MCP Server (`mem0-mcp-server`)
**Responsibilities:**
- Expose memory operations as MCP tools
- Validate requests and parameters
- Forward operations to Mem0 Platform API
- Handle authentication via API key
- Return structured responses

**Tools Exposed:**
- `add_memory` - Create new memory
- `search_memories` - Semantic search
- `get_memories` - List with filters
- `get_memory` - Retrieve by ID
- `update_memory` - Modify existing
- `delete_memory` - Remove by ID
- `delete_all_memories` - Bulk delete
- `delete_entities` - Remove entity
- `list_entities` - List stored entities

---

### 3. Mem0 Platform Layer

#### Mem0 REST API
**Endpoint:** `https://api.mem0.ai/v1/`

**Authentication:** Bearer token (API key)

**Key Endpoints:**
- `POST /v1/memories` - Add memory
- `POST /v1/memories/search` - Search memories
- `GET /v1/memories` - List memories
- `GET /v1/memories/{id}` - Get memory
- `PUT /v1/memories/{id}` - Update memory
- `DELETE /v1/memories/{id}` - Delete memory

#### Memory Store
**Responsibilities:**
- Persist memory records
- Manage memory metadata
- Handle memory lifecycle
- Enforce access control per user_id/agent_id

#### Vector Database
**Responsibilities:**
- Store embedding vectors
- Perform similarity search
- Return ranked results

#### LLM Processing
**Responsibilities:**
- Extract structured facts from conversations
- Generate embeddings for queries and memories
- Re-rank search results for relevance

---

## Modular Code Structure

For extensibility and custom tooling, here's a recommended modular structure:

```
mem0-claude-integration/
├── config/
│   ├── __init__.py
│   ├── env_loader.py          # Load and validate environment variables
│   ├── mcp_config.py           # MCP configuration management
│   └── settings.py             # Application settings
│
├── core/
│   ├── __init__.py
│   ├── client.py               # Mem0 API client wrapper
│   ├── models.py               # Data models (Memory, SearchResult, etc.)
│   └── exceptions.py           # Custom exceptions
│
├── memory/
│   ├── __init__.py
│   ├── operations.py           # Memory CRUD operations
│   ├── search.py               # Search and retrieval logic
│   └── filters.py              # Memory filtering utilities
│
├── mcp/
│   ├── __init__.py
│   ├── server.py               # MCP server implementation
│   ├── tools.py                # Tool definitions and handlers
│   └── protocol.py             # MCP protocol helpers
│
├── utils/
│   ├── __init__.py
│   ├── logging.py              # Logging configuration
│   ├── validation.py           # Input validation
│   └── formatters.py           # Response formatting
│
├── scripts/
│   ├── setup.sh                # Initial setup script
│   ├── test_integration.py     # Integration tests
│   └── check_health.py         # Health check utility
│
├── docs/
│   ├── LLD.md                  # This document
│   ├── API.md                  # API documentation
│   └── USAGE.md                # Usage guide
│
├── claude-mem0.env.example     # Environment template
├── claude-mem0.env             # Actual env (git-ignored)
├── requirements.txt            # Python dependencies
└── README.md                   # Project overview
```

### Module Responsibilities

#### `config/` - Configuration Management
```python
# config/env_loader.py
from typing import Optional
import os

class EnvConfig:
    """Load and validate environment variables."""

    def __init__(self):
        self.api_key: str = self._get_required("MEM0_API_KEY")
        self.user_id: str = self._get_required("MEM0_DEFAULT_USER_ID")
        self.enable_graph: bool = self._get_optional("MEM0_ENABLE_GRAPH_DEFAULT", "false") == "true"

    @staticmethod
    def _get_required(key: str) -> str:
        value = os.getenv(key)
        if not value:
            raise ValueError(f"Required environment variable {key} not set")
        return value

    @staticmethod
    def _get_optional(key: str, default: str) -> str:
        return os.getenv(key, default)
```

#### `core/` - Core Abstractions
```python
# core/models.py
from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime

@dataclass
class Memory:
    """Represents a memory record."""
    id: str
    content: str
    user_id: Optional[str] = None
    agent_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

@dataclass
class SearchResult:
    """Represents a search result."""
    memory: Memory
    score: float

@dataclass
class SearchResponse:
    """Represents search response."""
    results: List[SearchResult]
    total: int
```

```python
# core/client.py
import requests
from typing import List, Optional, Dict, Any
from .models import Memory, SearchResponse
from config.env_loader import EnvConfig

class Mem0Client:
    """Client for Mem0 Platform API."""

    def __init__(self, config: EnvConfig):
        self.api_key = config.api_key
        self.base_url = "https://api.mem0.ai/v1"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    def add_memory(
        self,
        content: str,
        user_id: Optional[str] = None,
        agent_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Memory:
        """Add a new memory."""
        payload = {
            "messages": [{"role": "user", "content": content}]
        }
        if user_id:
            payload["user_id"] = user_id
        if agent_id:
            payload["agent_id"] = agent_id
        if metadata:
            payload["metadata"] = metadata

        response = requests.post(
            f"{self.base_url}/memories",
            headers=self.headers,
            json=payload
        )
        response.raise_for_status()
        return Memory(**response.json())

    def search_memories(
        self,
        query: str,
        user_id: Optional[str] = None,
        agent_id: Optional[str] = None,
        limit: int = 10
    ) -> SearchResponse:
        """Search memories."""
        payload = {"query": query, "limit": limit}
        if user_id:
            payload["user_id"] = user_id
        if agent_id:
            payload["agent_id"] = agent_id

        response = requests.post(
            f"{self.base_url}/memories/search",
            headers=self.headers,
            json=payload
        )
        response.raise_for_status()
        return SearchResponse(**response.json())
```

#### `memory/` - Memory Operations
```python
# memory/operations.py
from typing import Optional, List, Dict, Any
from core.client import Mem0Client
from core.models import Memory, SearchResponse

class MemoryOperations:
    """High-level memory operations."""

    def __init__(self, client: Mem0Client, default_user_id: str):
        self.client = client
        self.default_user_id = default_user_id

    def remember(
        self,
        content: str,
        scope: str = "user",
        metadata: Optional[Dict[str, Any]] = None
    ) -> Memory:
        """Remember information."""
        if scope == "user":
            return self.client.add_memory(
                content=content,
                user_id=self.default_user_id,
                metadata=metadata
            )
        elif scope == "project":
            project_id = metadata.get("project_id") if metadata else None
            return self.client.add_memory(
                content=content,
                agent_id=project_id,
                metadata=metadata
            )
        else:
            raise ValueError(f"Invalid scope: {scope}")

    def recall(
        self,
        query: str,
        scope: str = "user",
        limit: int = 5
    ) -> List[Memory]:
        """Recall relevant memories."""
        if scope == "user":
            response = self.client.search_memories(
                query=query,
                user_id=self.default_user_id,
                limit=limit
            )
        elif scope == "project":
            # Assume project context is set in metadata
            response = self.client.search_memories(
                query=query,
                limit=limit
            )
        else:
            raise ValueError(f"Invalid scope: {scope}")

        return [result.memory for result in response.results]
```

#### `mcp/` - MCP Server Implementation
```python
# mcp/tools.py
from typing import Dict, Any, Callable
from memory.operations import MemoryOperations

class MemoryTools:
    """MCP tool implementations."""

    def __init__(self, operations: MemoryOperations):
        self.ops = operations

    def get_tool_definitions(self) -> Dict[str, Callable]:
        """Get all tool definitions."""
        return {
            "add_memory": self.add_memory_tool,
            "search_memories": self.search_memories_tool,
            "get_memories": self.get_memories_tool,
            # ... other tools
        }

    def add_memory_tool(self, content: str, **kwargs) -> Dict[str, Any]:
        """Add memory tool handler."""
        try:
            memory = self.ops.remember(content, **kwargs)
            return {
                "success": True,
                "memory_id": memory.id,
                "content": memory.content
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    def search_memories_tool(self, query: str, **kwargs) -> Dict[str, Any]:
        """Search memories tool handler."""
        try:
            memories = self.ops.recall(query, **kwargs)
            return {
                "success": True,
                "results": [
                    {"content": m.content, "id": m.id}
                    for m in memories
                ]
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
```

---

## Data Models

### Memory Entity

```mermaid
classDiagram
    class Memory {
        +String id
        +String content
        +String user_id
        +String agent_id
        +String run_id
        +Dict metadata
        +DateTime created_at
        +DateTime updated_at
        +List~String~ tags
        +Float relevance_score
    }

    class MemoryMetadata {
        +String namespace
        +String git_repo_name
        +String git_branch
        +String git_commit_hash
        +List~String~ memory_types
        +Dict custom_fields
    }

    class SearchQuery {
        +String query
        +String user_id
        +String agent_id
        +Int limit
        +List~String~ filters
        +List~String~ namespaces
    }

    class SearchResult {
        +Memory memory
        +Float score
        +String relevance_reason
    }

    Memory --> MemoryMetadata
    SearchQuery --> SearchResult
    SearchResult --> Memory
```

---

## State Management

### Memory Lifecycle States

```mermaid
stateDiagram-v2
    [*] --> Creating: User request
    Creating --> Active: Successfully stored
    Creating --> Failed: Validation/API error

    Active --> Updating: Update request
    Updating --> Active: Update successful
    Updating --> Failed: Update error

    Active --> Searching: Search query
    Searching --> Active: Results returned

    Active --> Deleting: Delete request
    Deleting --> Deleted: Delete successful
    Deleting --> Failed: Delete error

    Deleted --> [*]
    Failed --> [*]: Error handled
```

---

## Error Handling

### Error Types and Handling Strategy

```mermaid
graph TD
    subgraph ErrorTypes["Error Types"]
        ConfigError[Configuration Error]
        AuthError[Authentication Error]
        NetworkError[Network Error]
        ValidationError[Validation Error]
        APIError[API Error]
    end

    subgraph Handling["Error Handling"]
        Log[Log Error]
        Retry[Retry with Backoff]
        Fallback[Use Fallback]
        UserNotify[Notify User]
        Abort[Abort Operation]
    end

    ConfigError --> Log
    ConfigError --> UserNotify
    ConfigError --> Abort

    AuthError --> Log
    AuthError --> UserNotify
    AuthError --> Abort

    NetworkError --> Log
    NetworkError --> Retry
    NetworkError -->|Max retries| UserNotify

    ValidationError --> Log
    ValidationError --> UserNotify

    APIError --> Log
    APIError --> Retry
    APIError -->|5xx errors| Retry
    APIError -->|4xx errors| UserNotify
```

---

## Performance Considerations

### Caching Strategy

```mermaid
graph LR
    subgraph ClientCache["Client-Side Cache"]
        RecentMem[Recent Memories<br/>TTL: 5 min]
        SearchCache[Search Results<br/>TTL: 2 min]
    end

    subgraph ServerCache["Server-Side Cache (Mem0)"]
        EmbedCache[Embedding Cache<br/>TTL: 1 hour]
        VectorCache[Vector Index<br/>Persistent]
    end

    Query[User Query] -->|Check cache| SearchCache
    SearchCache -->|Cache miss| MCPServer[MCP Server]
    MCPServer --> Mem0API[Mem0 API]
    Mem0API -->|Check cache| EmbedCache
    EmbedCache -->|Cache miss| VectorDB[Vector DB]
    VectorDB --> VectorCache
```

### Optimization Strategies

1. **Batch Operations**
   - Group multiple memory additions
   - Reduce API calls

2. **Lazy Loading**
   - Load full memory details on demand
   - Return metadata first

3. **Connection Pooling**
   - Reuse HTTP connections
   - Reduce connection overhead

4. **Async Operations**
   - Non-blocking memory operations
   - Background processing for non-critical updates

---

## Security Design

### Security Layers

```mermaid
graph TB
    subgraph Transport["Transport Security"]
        HTTPS[HTTPS/TLS 1.3]
    end

    subgraph Authentication["Authentication"]
        APIKey[API Key<br/>Bearer Token]
        EnvVar[Environment Variables]
    end

    subgraph Authorization["Authorization"]
        UserScope[User Scoping<br/>user_id]
        AgentScope[Agent Scoping<br/>agent_id]
        RBAC[Role-Based Access]
    end

    subgraph DataProtection["Data Protection"]
        Encryption[At-Rest Encryption]
        GitIgnore[Git-Ignored Secrets]
        NoLogging[No Secret Logging]
    end

    HTTPS --> APIKey
    APIKey --> EnvVar
    EnvVar --> UserScope
    UserScope --> AgentScope
    AgentScope --> RBAC
    RBAC --> Encryption
    Encryption --> GitIgnore
    GitIgnore --> NoLogging
```

### Best Practices

1. **Never hardcode API keys** - Always use environment variables
2. **Git-ignore sensitive files** - `claude-mem0.env` must be in `.gitignore`
3. **Rotate keys regularly** - Generate new API keys periodically
4. **Scope access appropriately** - Use `user_id` and `agent_id` correctly
5. **Validate inputs** - Sanitize before sending to API
6. **Use HTTPS only** - Never transmit over unsecured connections

---

## Deployment Architecture

### Cross-Device Deployment

```mermaid
graph TB
    subgraph Device1["Device 1 (Laptop)"]
        CC1[Claude Code]
        MCP1[MCP Server]
        Env1[claude-mem0.env<br/>USER_ID: ankur]
    end

    subgraph Device2["Device 2 (Desktop)"]
        CC2[Claude Code]
        MCP2[MCP Server]
        Env2[claude-mem0.env<br/>USER_ID: ankur]
    end

    subgraph Device3["Device 3 (VM)"]
        CC3[Claude Code]
        MCP3[MCP Server]
        Env3[claude-mem0.env<br/>USER_ID: ankur]
    end

    subgraph Cloud["Mem0 Platform Cloud"]
        Mem0[Mem0 API]
        DB[(Shared Memory Store<br/>for user: ankur)]
    end

    CC1 --> MCP1
    CC2 --> MCP2
    CC3 --> MCP3

    MCP1 -->|API_KEY| Mem0
    MCP2 -->|API_KEY| Mem0
    MCP3 -->|API_KEY| Mem0

    Mem0 --> DB

    style DB fill:#90EE90
```

**Key Points:**
- Same `USER_ID` across all devices = shared memory
- Same `API_KEY` for authentication
- Cloud-based sync ensures consistency
- No local storage conflicts

---

## Testing Strategy

### Test Pyramid

```mermaid
graph TB
    subgraph TestTypes["Test Levels"]
        E2E[End-to-End Tests<br/>Claude Code + MCP + Mem0]
        Integration[Integration Tests<br/>MCP Server + Mem0 API]
        Unit[Unit Tests<br/>Individual modules]
    end

    Unit -->|Build on| Integration
    Integration -->|Build on| E2E

    style Unit fill:#90EE90
    style Integration fill:#FFE4B5
    style E2E fill:#FFB6C1
```

### Test Scenarios

1. **Unit Tests**
   - Config loading and validation
   - Memory model serialization
   - Error handling logic

2. **Integration Tests**
   - MCP server tool invocation
   - Mem0 API calls
   - Response parsing

3. **End-to-End Tests**
   - Full workflow: Claude Code → MCP → Mem0
   - Memory persistence and retrieval
   - Cross-device sync

---

## Monitoring and Observability

### Key Metrics

1. **Performance Metrics**
   - API response time
   - Memory operation latency
   - Cache hit rate

2. **Reliability Metrics**
   - Success rate
   - Error rate by type
   - Retry attempts

3. **Usage Metrics**
   - Memories created per day
   - Search queries per day
   - Active users

### Logging Strategy

```python
# utils/logging.py
import logging
from typing import Any

class MemoryLogger:
    """Structured logging for memory operations."""

    def __init__(self):
        self.logger = logging.getLogger("mem0-claude")
        self.logger.setLevel(logging.INFO)

    def log_operation(
        self,
        operation: str,
        user_id: str,
        success: bool,
        **kwargs: Any
    ):
        """Log memory operation."""
        self.logger.info(
            f"Operation: {operation}",
            extra={
                "operation": operation,
                "user_id": user_id,
                "success": success,
                **kwargs
            }
        )
```

---

## Future Enhancements

### Potential Extensions

1. **Local Caching Layer**
   ```
   Claude Code → Local Cache → MCP → Mem0
   - Offline support
   - Faster retrieval
   ```

2. **Memory Compression**
   - Summarize old memories
   - Reduce storage costs

3. **Advanced Search**
   - Temporal filtering
   - Tag-based organization
   - Relationship graphs

4. **Multi-Agent Collaboration**
   - Shared agent memories
   - Team workspaces

5. **Analytics Dashboard**
   - Memory usage insights
   - Search patterns
   - Productivity metrics

---

## Appendix

### Glossary

- **MCP**: Model Context Protocol - Standard for AI tool integration
- **Memory**: A stored piece of information with context
- **User ID**: Identifier for personal memory scope
- **Agent ID**: Identifier for project/agent-specific memory
- **Run ID**: Identifier for session-specific memory
- **Namespace**: Logical grouping of memories
- **Embedding**: Vector representation of text for similarity search

### References

- [Claude Code Documentation](https://code.claude.com/docs/en/overview)
- [Mem0 Platform Documentation](https://docs.mem0.ai)
- [Model Context Protocol Specification](https://modelcontextprotocol.io)
- [Mem0 MCP Server Repository](https://github.com/mem0ai/mem0-mcp)

---

**Document Version:** 1.0
**Last Updated:** January 7, 2026
**Author:** AI Assistant
**Status:** Draft
