require "json"

module ModelContextProtocol
  module Server
    # Base class for MCP Resources
    abstract class Resource
      include JSON::Serializable

      property uri : String
      property metadata : Hash(String, JSON::Any)

      def initialize(@uri, @metadata = {} of String => JSON::Any)
      end

      # Read the resource content
      abstract def read : String

      # Optional: Subscribe to resource changes
      def subscribe : Bool
        false
      end

      # Optional: Unsubscribe from resource changes
      def unsubscribe : Bool
        false
      end
    end

    # Resource-related errors
    class ResourceError < Exception
    end
  end
end
