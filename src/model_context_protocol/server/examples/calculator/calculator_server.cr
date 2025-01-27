require "../../server"
require "./tools/*"

module ModelContextProtocol
  module Server
    module Examples
      module Calculator
        # Example Calculator MCP Server implementation that provides basic arithmetic operations.
        # This server demonstrates how to create a custom MCP server with specific tools.
        #
        # Example:
        # ```crystal
        # server = CalculatorServer.new
        # server.start # Starts the server on localhost:8080
        # ```
        class CalculatorServer < Server
          def initialize(host : String = "localhost", port : Int32 = 8080)
            super(host, port)

            # Register calculator tools
            register_tool(Tools::AdditionTool.new)
            register_tool(Tools::SubtractionTool.new)
          end
        end
      end
    end
  end
end
