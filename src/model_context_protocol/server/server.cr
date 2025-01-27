require "json"
require "http/server"
require "../messages"
require "./tool"
require "./capabilities"
require "./utilities/logging"
require "../http_transport"

module ModelContextProtocol
  module Server
    
    # Main MCP Server class that implements the Model Context Protocol.
    # This class provides the core server functionality including:
    # - HTTP+SSE transport handling
    # - Tool registration and management
    # - Protocol message handling
    # - Connection lifecycle management
    #
    # Example:
    # ```crystal
    # class MyServer < ModelContextProtocol::Server::Server
    #   def initialize
    #     super("localhost", 8080)
    #     register_tool(MyTool.new)
    #   end
    # end
    #
    # server = MyServer.new
    # server.start # Starts the server on localhost:8080
    # ```
    abstract class Server
      VERSION = "0.1.0"

      # Default paths for HTTP endpoints
      SSE_ENDPOINT     = "/events"
      MESSAGE_ENDPOINT = "/"

      private getter tools : Hash(String, Tool)
      private getter capabilities : Capabilities
      private getter logger : Utilities::Logging
      private getter http_server : HTTP::Server
      private property? initialized : Bool
      private getter host : String
      private getter port : Int32

      @transport : Transport::Base?

      # Initialize a new MCP server
      #
      # Parameters:
      # - host: The hostname to bind to (default: "localhost")
      # - port: The port to listen on (default: 8080)
      def initialize(@host = "localhost", @port = 8080)
        @tools = {} of String => Tool
        @capabilities = Capabilities.new
        @initialized = false
        @logger = Utilities::Logging.new
        @http_server = HTTP::Server.new do |context|
          case context.request.path
          when SSE_ENDPOINT
            handle_sse_request(context)
          when MESSAGE_ENDPOINT
            handle_message_request(context)
          else
            context.response.status_code = 404
            context.response.print "Not Found"
          end
        end
        setup_request_handlers
      end

      private def transport : Transport::Base
        @transport ||= begin
          transport = Transport::HttpTransport.new(@http_server)
          @logger.transport = transport
          transport
        end
      end

      # Start the server and begin accepting connections
      def start : Nil
        @logger.info("Starting server on #{@host}:#{@port}", "server")
        
        # Start HTTP server in a separate fiber
        spawn do
          @http_server.bind_tcp(@host, @port)
          @http_server.listen
        end
      end

      # Stop the server and close all connections
      def stop : Nil
        @logger.info("Stopping server", "server")
        transport.close
        begin
          @http_server.close
        rescue ex : Exception
          @logger.error("Error closing server: #{ex.message}", "server")
        end
      end

      # Register a tool with the server
      #
      # Parameters:
      # - tool: The tool instance to register
      def register_tool(tool : Tool) : Nil
        @tools[tool.name] = tool
      end

      private def handle_sse_request(context : HTTP::Server::Context) : Nil
        response = context.response
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["Connection"] = "keep-alive"
        response.headers["Access-Control-Allow-Origin"] = "*"

        # Keep the connection alive with periodic pings
        spawn do
          loop do
            response.puts "data: ping\n\n"
            response.flush
            sleep 30.seconds
          end
        end

        # Handle notifications
        transport.on_notification do |notification|
          response.puts "data: #{notification.to_json}\n\n"
          response.flush
        end

        # Keep the connection open
        sleep
      end

      private def handle_message_request(context : HTTP::Server::Context) : Nil
        context.response.content_type = "application/json"
        
        begin
          request = Messages::Request.from_json(context.request.body.not_nil!)
          response = handle_request(request)
          context.response.print response.to_json
        rescue ex : Exception
          error_response = Messages::Response.new(
            "0",
            error: Messages::Error.new(
              Messages::ErrorCodes::PARSE_ERROR,
              "Failed to parse request: #{ex.message}"
            )
          )
          context.response.print error_response.to_json
        end
      end

      private def setup_request_handlers
        transport.on_request do |request|
          handle_request(request)
        end

        transport.on_notification do |notification|
          handle_notification(notification)
        end
      end

      private def handle_request(request : Messages::Request) : Messages::Response
        case request.method
        when "initialize"
          handle_initialize(request)
        when "tools/list"
          handle_list_tools(request)
        when "tools/invoke"
          handle_invoke_tool(request)
        else
          Messages::Response.new(
            request.id,
            error: Messages::Error.new(
              Messages::ErrorCodes::METHOD_NOT_FOUND,
              "Method not found: #{request.method}"
            )
          )
        end
      rescue ex : Exception
        Messages::Response.new(
          request.id,
          error: Messages::Error.new(
            Messages::ErrorCodes::INTERNAL_ERROR,
            "Internal error: #{ex.message}"
          )
        )
      end

      private def handle_notification(notification : Messages::Notification) : Nil
        case notification.method
        when "notifications/initialized"
          @initialized = true
          @logger.info("Client initialized", "server")
        end
      rescue ex : Exception
        @logger.error("Error handling notification: #{ex.message}", "server")
      end

      private def handle_initialize(request : Messages::Request) : Messages::Response
        params = request.params
        raise "Missing parameters" unless params

        client_version = params["protocolVersion"]?.try(&.as_s)
        raise "Protocol version mismatch" unless client_version == VERSION

        client_capabilities = params["capabilities"]?.try(&.as_h) || {} of String => JSON::Any
        @capabilities.update(client_capabilities)

        Messages::Response.new(
          request.id,
          result: {
            "protocolVersion" => JSON::Any.new(VERSION),
            "capabilities" => JSON::Any.new(@capabilities.to_h),
            "serverInfo" => JSON::Any.new({
              "name" => JSON::Any.new("Crystal MCP Server"),
              "version" => JSON::Any.new(VERSION)
            })
          }
        )
      end

      private def handle_list_tools(request : Messages::Request) : Messages::Response
        params = request.params
        cursor = params.try(&.[]?("cursor")).try(&.as_s)

        # For now, return all tools without pagination
        tools_json = @tools.values.map do |tool|
          tool_json = {
            "name" => JSON::Any.new(tool.name),
            "description" => JSON::Any.new(tool.description),
            "parameters" => JSON::Any.new(tool.parameters),
            "requiredParameters" => JSON::Any.new(tool.required_parameters.map { |p| JSON::Any.new(p) })
          }
          JSON::Any.new(tool_json)
        end

        Messages::Response.new(
          request.id,
          result: {
            "tools" => JSON::Any.new(tools_json),
            "nextCursor" => JSON::Any.new(cursor)
          }
        )
      end

      private def handle_invoke_tool(request : Messages::Request) : Messages::Response
        params = request.params
        raise "Missing parameters" unless params

        tool_name = params["name"]?.try(&.as_s)
        raise "Missing tool name" unless tool_name

        tool = @tools[tool_name]?
        raise "Tool not found: #{tool_name}" unless tool

        tool_params = params["params"]?.try(&.as_h) || {} of String => JSON::Any
        result = tool.invoke(tool_params)

        Messages::Response.new(request.id, result: result)
      rescue ex : ToolError
        Messages::Response.new(
          request.id,
          error: Messages::Error.new(
            Messages::ErrorCodes::INVALID_PARAMS,
            ex.message || "Tool error"
          )
        )
      rescue ex : Exception
        Messages::Response.new(
          request.id,
          error: Messages::Error.new(
            Messages::ErrorCodes::INTERNAL_ERROR,
            "Internal error: #{ex.message}"
          )
        )
      end
    end
  end
end
