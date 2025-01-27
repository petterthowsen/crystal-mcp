require "./messages"
require "json_rpc"

module ModelContextProtocol
  module Transport
    # Abstract base class for all MCP transports
    abstract class Base
      # Send a request and wait for response
      abstract def send_request(request : Messages::Request) : Messages::Response

      # Send a notification (no response expected)
      abstract def send_notification(notification : Messages::Notification) : Nil

      # Handle incoming requests
      abstract def on_request(&block : Messages::Request -> Messages::Response)

      # Handle incoming notifications
      abstract def on_notification(&block : Messages::Notification -> Nil)

      # Close the transport
      abstract def close : Nil
    end

    # Error raised when transport-related issues occur
    class TransportError < Exception
    end

    # Error raised when protocol-related issues occur
    class ProtocolError < Exception
    end
  end
end
