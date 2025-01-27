require "json"

module ModelContextProtocol
  class Client
    # Represents a filesystem root in MCP
    class Root
      include JSON::Serializable

      property uri : String
      property name : String?

      def initialize(@uri, @name = nil)
      end

      def to_json_object : Hash(String, JSON::Any)
        obj = {
          "uri" => JSON::Any.new(@uri)
        } of String => JSON::Any

        if name = @name
          obj["name"] = JSON::Any.new(name)
        end

        obj
      end
    end
  end
end
