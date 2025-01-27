require "../../server"
require "./tools/*"
require "http/server"

module ModelContextProtocol
  module Server
    module Examples
      module Calculator
        # Example Calculator MCP Server implementation
        class CalculatorServer < Server
          def initialize(host : String = "localhost", port : Int32 = 8080)
            http_server = HTTP::Server.new do |context|
              handle_http_request(context)
            end

            transport = Transport::HttpTransport.new(http_server)
            super(transport)

            # Register calculator tools
            register_tool(Tools::AdditionTool.new)
            register_tool(Tools::SubtractionTool.new)

            # Start HTTP server
            spawn do
              http_server.bind_tcp(host, port)
              http_server.listen
            end
          end

          # Start the server
          def start : Nil
            super
            @logger.info("Calculator server started", "calculator")
          end

          # Stop the server
          def stop : Nil
            super
            @logger.info("Calculator server stopped", "calculator")
          end

          private def handle_http_request(context : HTTP::Server::Context)
            case context.request.path
            when "/"
              handle_rpc_request(context)
            when "/events"
              handle_sse_request(context)
            else
              context.response.status_code = 404
              context.response.print "Not Found"
            end
          end

          private def handle_rpc_request(context : HTTP::Server::Context)
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

          private def handle_sse_request(context : HTTP::Server::Context)
            response = context.response
            response.headers["Content-Type"] = "text/event-stream"
            response.headers["Cache-Control"] = "no-cache"
            response.headers["Connection"] = "keep-alive"
            response.headers["Access-Control-Allow-Origin"] = "*"

            # Keep the connection alive
            spawn do
              loop do
                response.puts "data: ping\n\n"
                response.flush
                sleep 30.seconds
              end
            end

            # Handle notifications
            @transport.on_notification do |notification|
              response.puts "data: #{notification.to_json}\n\n"
              response.flush
            end

            # Keep the connection open
            sleep
          end
        end
      end
    end
  end
end
