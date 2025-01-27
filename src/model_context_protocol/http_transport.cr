require "http/client"
require "http/server"
require "sse"
require "json_rpc"
require "./transport"
require "./messages"

module ModelContextProtocol
  module Transport
    # Implementation of MCP transport using HTTP+SSE
    class HttpTransport < Base
      private getter http_client : HTTP::Client?
      private getter http_server : HTTP::Server?
      private getter request_handlers : Array(Messages::Request -> Messages::Response)
      private getter notification_handlers : Array(Messages::Notification -> Nil)
      private property? is_server : Bool
      
      # Initialize as client
      def initialize(host : String, port : Int32)
        @http_client = HTTP::Client.new(host, port)
        @http_server = nil
        @request_handlers = [] of Messages::Request -> Messages::Response
        @notification_handlers = [] of Messages::Notification -> Nil
        @is_server = false
      end

      # Initialize as server
      def initialize(server : HTTP::Server)
        @http_client = nil
        @http_server = server
        @request_handlers = [] of Messages::Request -> Messages::Response
        @notification_handlers = [] of Messages::Notification -> Nil
        @is_server = true
      end

      # Send a request via HTTP POST and wait for response
      def send_request(request : Messages::Request) : Messages::Response
        client = @http_client
        raise "Not initialized as client" unless client

        response = client.post("/", 
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: request.to_json
        )
        
        Messages::Response.from_json(response.body)
      rescue ex : JSON::ParseException
        Messages::Response.new(
          request.id,
          error: Messages::Error.new(
            Messages::ErrorCodes::PARSE_ERROR,
            "Failed to parse response: #{ex.message}"
          )
        )
      rescue ex
        Messages::Response.new(
          request.id,
          error: Messages::Error.new(
            Messages::ErrorCodes::INTERNAL_ERROR,
            "Transport error: #{ex.message}"
          )
        )
      end

      # Send a notification via HTTP POST (no response expected)
      def send_notification(notification : Messages::Notification) : Nil
        if is_server?
          # Server-side notifications are handled by registered handlers
          @notification_handlers.each do |handler|
            begin
              handler.call(notification)
            rescue ex
              Log.error { "Failed to handle notification: #{ex.message}" }
            end
          end
        else
          # Client-side notifications are sent via HTTP POST
          client = @http_client
          raise "Not initialized as client" unless client

          client.post("/", 
            headers: HTTP::Headers{"Content-Type" => "application/json"},
            body: notification.to_json
          )
        end
      rescue ex
        # Log error but don't raise since notifications don't expect responses
        Log.error { "Failed to send notification: #{ex.message}" }
      end

      # Register a handler for incoming requests via SSE
      def on_request(&block : Messages::Request -> Messages::Response)
        @request_handlers << block
      end

      # Register a handler for incoming notifications via SSE
      def on_notification(&block : Messages::Notification -> Nil)
        @notification_handlers << block
      end

      # Close all connections
      def close : Nil
        @http_client.try &.close
        @http_server.try &.close
      end
    end
  end
end
