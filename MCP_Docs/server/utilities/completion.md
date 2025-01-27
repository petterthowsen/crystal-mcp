# Completion

The Model Context Protocol (MCP) provides a standardized way for servers to offer argument autocompletion suggestions for prompts and resource URIs. This enables rich, IDE-like experiences where users receive contextual suggestions while entering argument values.

## User Interaction Model

Completion in MCP is designed to support interactive user experiences similar to IDE code completion. For example, applications may show completion suggestions in a dropdown or popup menu as users type, with the ability to filter and select from available options.

## Protocol Messages

### Requesting Completions

To get completion suggestions, clients send a `completion/complete` request specifying what is being completed through a reference type:

Request:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "completion/complete",
  "params": {
    "ref": {
      "type": "ref/prompt",
      "name": "code_review"
    },
    "argument": {
      "name": "language",
      "value": "py"
    }
  }
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "completion": {
      "values": ["python", "pytorch", "pyside"],
      "total": 10,
      "hasMore": true
    }
  }
}
```

### Reference Types

The protocol supports two types of completion references:

1. Prompt References:
```json
{"type": "ref/prompt", "name": "code_review"}
```

2. Resource References:
```json
{"type": "ref/resource", "uri": "file:///{path}"}
```

### Completion Results

Servers return an array of completion values ranked by relevance, with:
- Maximum 100 items per response
- Optional total number of available matches
- Boolean indicating if additional results exist

## Implementation Considerations

Servers SHOULD:
- Return suggestions sorted by relevance
- Implement fuzzy matching where appropriate
- Rate limit completion requests
- Validate all inputs

Clients SHOULD:
- Debounce rapid completion requests
- Cache completion results where appropriate
- Handle missing or partial results gracefully

## Security

Implementations MUST:
- Validate all completion inputs
- Implement appropriate rate limiting
- Control access to sensitive suggestions
- Prevent completion-based information disclosure
