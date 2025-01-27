require "json"
require "../messages"
require "./tool"
require "./capabilities"
require "./utilities/logging"

module ModelContextProtocol
  module Server
    # Main MCP Server class
    class Server
      VERSION = "0.1.0"

      private getter tools : Hash(String, Tool)
      private getter capabilities : Capabilities
      private getter transport : Transport::Base
      private getter logger : Utilities::Logging
      private property? initialized : Bool

      def initialize(@transport)
        @tools = {} of String => Tool
        @capabilities = Capabilities.new
        @logger = Utilities::Logging.new(@transport)
        @initialized = false

        setup_request_handlers
      end

      # Register a tool with the server
      def register_tool(tool : Tool) : Nil
        @tools[tool.name] = tool
      end

      # Start the server
      def start : Nil
        @logger.info("Server started", "server")
      end

      # Stop the server
      def stop : Nil
        @transport.close
      end

      private def setup_request_handlers
        @transport.on_request do |request|
          handle_request(request)
        end

        @transport.on_notification do |notification|
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
