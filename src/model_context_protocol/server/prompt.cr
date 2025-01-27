require "json"

module ModelContextProtocol
  module Server
    # Base class for MCP Prompts
    abstract class Prompt
      include JSON::Serializable

      property name : String
      property template : String
      property args : Hash(String, JSON::Any)
      property description : String
      property required_args : Array(String)

      def initialize(@name, @template, @description, @args = {} of String => JSON::Any, @required_args = [] of String)
      end

      # Render the prompt template with given values
      def render(values : Hash(String, JSON::Any)) : String
        validate_args!(values)
        
        result = template
        values.each do |key, value|
          result = result.gsub("{{#{key}}}", value.to_s)
        end
        
        result
      end

      # Validate arguments
      protected def validate_args!(values : Hash(String, JSON::Any)) : Nil
        @required_args.each do |arg|
          unless values[arg]?
            raise PromptError.new("Missing required argument: #{arg}")
          end
        end
      end
    end

    # Prompt-related errors
    class PromptError < Exception
    end
  end
end
