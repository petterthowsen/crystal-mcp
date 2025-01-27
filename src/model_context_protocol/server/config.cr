module ModelContextProtocol
  module Server
    # Server configuration
    class Config
      property host : String
      property port : Int32
      property capabilities : Capabilities

      def initialize(@host = "localhost", @port = 8080)
        @capabilities = Capabilities.new
      end

      # Configure server capabilities
      def configure_capabilities(&block : Capabilities -> Nil) : Nil
        block.call(@capabilities)
      end
    end
  end
end
