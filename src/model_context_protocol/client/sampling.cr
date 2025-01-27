require "json"

module ModelContextProtocol
  class Client
    # Message content types for sampling
    module MessageContent
      # Base class for all message content types
      abstract class Base
        include JSON::Serializable

        use_json_discriminator "type", {
          "text" => TextContent,
          "image" => ImageContent
        }

        abstract def to_json_object : Hash(String, JSON::Any)
      end

      # Text content for messages
      class TextContent < Base
        property type : String = "text"
        property text : String

        def initialize(@text)
        end

        def to_json_object : Hash(String, JSON::Any)
          {
            "type" => JSON::Any.new(@type),
            "text" => JSON::Any.new(@text)
          }
        end
      end

      # Image content for messages
      class ImageContent < Base
        property type : String = "image"
        property data : String
        property mime_type : String

        def initialize(@data, @mime_type)
        end

        def to_json_object : Hash(String, JSON::Any)
          {
            "type" => JSON::Any.new(@type),
            "data" => JSON::Any.new(@data),
            "mimeType" => JSON::Any.new(@mime_type)
          }
        end
      end
    end

    # Model preferences for sampling
    class ModelPreferences
      include JSON::Serializable

      class ModelHint
        include JSON::Serializable

        property name : String

        def initialize(@name)
        end

        def to_json_object : Hash(String, JSON::Any)
          {
            "name" => JSON::Any.new(@name)
          }
        end
      end

      property hints : Array(ModelHint)
      property cost_priority : Float64
      property speed_priority : Float64
      property intelligence_priority : Float64

      def initialize(
        @hints = [] of ModelHint,
        @cost_priority = 0.5,
        @speed_priority = 0.5,
        @intelligence_priority = 0.5
      )
      end

      def to_json_object : Hash(String, JSON::Any)
        {
          "hints" => JSON::Any.new(hints.map(&.to_json_object)),
          "costPriority" => JSON::Any.new(@cost_priority),
          "speedPriority" => JSON::Any.new(@speed_priority),
          "intelligencePriority" => JSON::Any.new(@intelligence_priority)
        }
      end
    end

    # Message for sampling requests and responses
    class Message
      include JSON::Serializable

      property role : String
      property content : MessageContent::Base
      property model : String?
      property stop_reason : String?

      def initialize(@role, @content, @model = nil, @stop_reason = nil)
      end

      def to_json_object : Hash(String, JSON::Any)
        obj = {
          "role" => JSON::Any.new(@role),
          "content" => JSON::Any.new(@content.to_json_object)
        } of String => JSON::Any

        if model = @model
          obj["model"] = JSON::Any.new(model)
        end

        if stop_reason = @stop_reason
          obj["stopReason"] = JSON::Any.new(stop_reason)
        end

        obj
      end
    end
  end
end
