# Model Context Protocol (MCP)

A Crystal implementation of the Model Context Protocol, providing a standardized way for AI/LLM applications to interact with external context providers. This implementation includes the core protocol, client, and server components.

## Features

- JSON-RPC 2.0 based protocol
- HTTP+SSE transport layer
- Modular tool registration system
- Comprehensive error handling
- Built-in parameter validation
- Example calculator implementation

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mcp:
       github: petterthowsen/mcp
   ```

2. Run `shards install`

## Usage

### Creating a Server

```crystal
require "mcp"

# Define a custom tool
class AdditionTool < ModelContextProtocol::Server::Tool
  def initialize
    parameters = {
      "a" => JSON::Any.new({
        "type" => JSON::Any.new("number"),
        "description" => JSON::Any.new("First number to add")
      }),
      "b" => JSON::Any.new({
        "type" => JSON::Any.new("number"),
        "description" => JSON::Any.new("Second number to add")
      })
    }

    super(
      name: "add",
      description: "Add two numbers together",
      parameters: parameters,
      required_parameters: ["a", "b"]
    )
  end

  def invoke(params : Hash(String, JSON::Any)) : Hash(String, JSON::Any)
    validate_params!(params)
    
    a = params["a"].as_f
    b = params["b"].as_f
    result = a + b

    {"result" => JSON::Any.new(result)}
  end
end

# Create and start the server
class MyServer < ModelContextProtocol::Server::Server
  def initialize(host : String = "localhost", port : Int32 = 8080)
    http_server = HTTP::Server.new do |context|
      handle_http_request(context)
    end

    transport = ModelContextProtocol::Transport::HttpTransport.new(http_server)
    super(transport)

    # Register tools
    register_tool(AdditionTool.new)

    # Start HTTP server
    spawn do
      http_server.bind_tcp(host, port)
      http_server.listen
    end
  end
end

server = MyServer.new
server.start
```

### Using the Client

```crystal
require "mcp"

# Create a client
transport = ModelContextProtocol::Transport::HttpTransport.new("localhost", 8080)
client = ModelContextProtocol::Client.new(transport)

# Initialize connection
client.initialize_connection

# List available tools
tools, cursor = client.list_tools
pp tools # => [{"name" => "add", "description" => "Add two numbers together", ...}]

# Invoke a tool
result = client.invoke_tool(
  "add",
  {
    "a" => JSON::Any.new(2.5),
    "b" => JSON::Any.new(1.7)
  }
)
pp result # => {"result" => 4.2}

# Close the connection
client.close
```

### Error Handling

The MCP implementation provides comprehensive error handling:

```crystal
begin
  result = client.invoke_tool(
    "add",
    {
      "a" => JSON::Any.new("not a number"), # Invalid parameter
      "b" => JSON::Any.new(1.0)
    }
  )
rescue ex : ModelContextProtocol::Server::ToolError
  puts "Tool error: #{ex.message}"
rescue ex : ModelContextProtocol::Client::InitializeError
  puts "Connection error: #{ex.message}"
end
```

## Development

1. Clone the repository
2. Run `shards install`
3. Run tests with `crystal spec`

For a complete example, check out the calculator implementation in `src/model_context_protocol/server/examples/calculator/`.

## Contributing

1. Fork it (<https://github.com/petterthowsen/mcp/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Petter Thowsen](https://github.com/petterthowsen) - creator and maintainer
