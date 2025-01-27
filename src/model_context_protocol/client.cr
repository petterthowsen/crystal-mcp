require "json"
require "./messages"
require "./transport"

module ModelContextProtocol
  # MCP Client implementation
  class Client
    VERSION = "0.1.0"

    class InitializeError < Exception; end

    private getter transport : Transport::Base
    private getter capabilities : Hash(String, JSON::Any)
    private getter server_info : Hash(String, JSON::Any)?
    private property? initialized : Bool

    def initialize(@transport)
      @capabilities = {} of String => JSON::Any
      @initialized = false
    end

    # Initialize the client-server connection
    def initialize_connection(client_capabilities = {} of String => JSON::Any) : Nil
      params = {
        "protocolVersion" => JSON::Any.new(VERSION),
        "capabilities" => JSON::Any.new(client_capabilities),
        "clientInfo" => JSON::Any.new({
          "name" => JSON::Any.new("Crystal MCP Client"),
          "version" => JSON::Any.new(VERSION)
        })
      }

      request = Messages::Request.new("1", "initialize", params)
      response = @transport.send_request(request)
      
      if error = response.error
        raise InitializeError.new(error.message)
      end

      result = response.result
      raise InitializeError.new("Invalid initialize response") unless result

      server_version = result["protocolVersion"]?.try(&.as_s)
      raise InitializeError.new("Protocol version mismatch") unless server_version == VERSION

      @capabilities = result["capabilities"].as_h
      @server_info = result["serverInfo"]?.try(&.as_h)

      # Send initialized notification
      @transport.send_notification(
        Messages::Notification.new("notifications/initialized")
      )

      @initialized = true
    end

    # List available tools
    def list_tools(cursor : String? = nil) : Tuple(Array(JSON::Any), String?)
      check_initialized!

      params = cursor ? {"cursor" => JSON::Any.new(cursor)} : nil
      request = Messages::Request.new("2", "tools/list", params)

      response = @transport.send_request(request)
      handle_response(response) do |result|
        tools = result["tools"].as_a
        next_cursor = result["nextCursor"]?.try(&.raw).try(&.as?(String))
        {tools, next_cursor}
      end
    end

    # Invoke a tool
    def invoke_tool(name : String, params : Hash(String, JSON::Any)) : Hash(String, JSON::Any)
      check_initialized!

      request = Messages::Request.new(
        "3",
        "tools/invoke",
        {
          "name" => JSON::Any.new(name),
          "params" => JSON::Any.new(params)
        } of String => JSON::Any
      )

      response = @transport.send_request(request)
      handle_response(response) do |result|
        result
      end
    end

    # Close the client connection
    def close : Nil
      @transport.close
    end

    private def check_initialized!
      raise InitializeError.new("Client not initialized") unless initialized?
    end

    private def handle_response(response : Messages::Response)
      if error = response.error
        raise Server::ToolError.new(error.message)
      end

      result = response.result
      raise Server::ToolError.new("Missing result") unless result

      yield result
    end
  end
end
