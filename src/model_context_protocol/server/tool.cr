require "json"

module ModelContextProtocol
  module Server
    # Base class for all MCP tools
    abstract class Tool
      getter name : String
      getter description : String
      getter parameters : Hash(String, JSON::Any)
      getter required_parameters : Array(String)

      def initialize(@name, @description, @parameters, @required_parameters)
      end

      # Get tool metadata as JSON
      def to_json_object : Hash(String, JSON::Any)
        {
          "name" => JSON::Any.new(@name),
          "description" => JSON::Any.new(@description),
          "parameters" => JSON::Any.new(@parameters),
          "required" => JSON::Any.new(@required_parameters.map { |p| JSON::Any.new(p) })
        }
      end

      # Invoke the tool with given parameters
      abstract def invoke(params : Hash(String, JSON::Any)) : Hash(String, JSON::Any)

      # Validate required parameters
      protected def validate_params!(params : Hash(String, JSON::Any)) : Nil
        missing = @required_parameters.select { |name| !params.has_key?(name) }
        unless missing.empty?
          raise ToolError.new("Missing required parameters: #{missing.join(", ")}")
        end
      end
    end

    # Error raised when tool execution fails
    class ToolError < Exception
    end
  end
end
