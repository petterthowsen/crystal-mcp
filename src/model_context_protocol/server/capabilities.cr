require "json"

module ModelContextProtocol
  module Server
    # Server capabilities
    class Capabilities
      include JSON::Serializable

      property tools : ToolsCapability?
      property resources : ResourcesCapability?
      property prompts : PromptsCapability?

      def initialize
        @tools = nil
        @resources = nil
        @prompts = nil
      end

      def update(capabilities : Hash(String, JSON::Any)) : Nil
        if tools_cap = capabilities["tools"]?.try(&.as_h)
          @tools = ToolsCapability.new
          @tools.try &.list_changed = tools_cap["listChanged"]?.try(&.as_bool) || false
        end

        if resources_cap = capabilities["resources"]?.try(&.as_h)
          @resources = ResourcesCapability.new
          @resources.try &.list_changed = resources_cap["listChanged"]?.try(&.as_bool) || false
        end

        if prompts_cap = capabilities["prompts"]?.try(&.as_h)
          @prompts = PromptsCapability.new
          @prompts.try &.list_changed = prompts_cap["listChanged"]?.try(&.as_bool) || false
        end
      end

      def to_h : Hash(String, JSON::Any)
        capabilities = {} of String => JSON::Any

        if tools = @tools
          capabilities["tools"] = JSON::Any.new({
            "listChanged" => JSON::Any.new(tools.list_changed)
          })
        end

        if resources = @resources
          capabilities["resources"] = JSON::Any.new({
            "listChanged" => JSON::Any.new(resources.list_changed)
          })
        end

        if prompts = @prompts
          capabilities["prompts"] = JSON::Any.new({
            "listChanged" => JSON::Any.new(prompts.list_changed)
          })
        end

        capabilities
      end
    end

    # Tool-related capabilities
    class ToolsCapability
      include JSON::Serializable

      property list_changed : Bool

      def initialize(@list_changed = false)
      end
    end

    # Resource-related capabilities
    class ResourcesCapability
      include JSON::Serializable

      property list_changed : Bool

      def initialize(@list_changed = false)
      end
    end

    # Prompt-related capabilities
    class PromptsCapability
      include JSON::Serializable

      property list_changed : Bool

      def initialize(@list_changed = false)
      end
    end
  end
end
