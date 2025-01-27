require "../prompt"

module ModelContextProtocol
  module Server
    module Examples
      # Example implementation of a code review prompt
      class CodeReviewPrompt < Prompt
        def initialize
          args = {
            "language" => JSON::Any.new({
              "type" => "string",
              "description" => "Programming language of the code"
            }),
            "code" => JSON::Any.new({
              "type" => "string",
              "description" => "Code to review"
            }),
            "focus" => JSON::Any.new({
              "type" => "string",
              "description" => "Specific aspects to focus on (optional)",
              "enum" => ["security", "performance", "maintainability", "all"]
            })
          }

          template = <<-TEMPLATE
          Please review the following {{language}} code:

          ```{{language}}
          {{code}}
          ```

          {% if focus != "all" %}
          Focus on {{focus}} aspects in your review.
          {% end %}

          Please provide:
          1. A summary of the code
          2. Identified issues or concerns
          3. Suggestions for improvement
          4. Code examples for suggested changes
          TEMPLATE

          super(
            name: "code_review",
            template: template,
            description: "Generate a comprehensive code review",
            args: args,
            required_args: ["language", "code"]
          )
        end

        def render(values : Hash(String, JSON::Any)) : String
          validate_args!(values)
          
          # Set default focus if not provided
          values["focus"] = JSON::Any.new("all") unless values["focus"]?
          
          super(values)
        end
      end
    end
  end
end
