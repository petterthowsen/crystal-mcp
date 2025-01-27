require "../../../tool"

module ModelContextProtocol
  module Server
    module Examples
      module Calculator
        module Tools
          # Tool for performing addition
          class AdditionTool < Tool
            def initialize
              parameters = {
                "a" => JSON::Any.new({
                  "type" => JSON::Any.new("number"),
                  "description" => JSON::Any.new("First number to add")
                }),
                "b" => JSON::Any.new({
                  "type" => JSON::Any.new("number"),
                  "description" => JSON::Any.new("Second number to add")
                })
              }

              super(
                name: "add",
                description: "Add two numbers together",
                parameters: parameters,
                required_parameters: ["a", "b"]
              )
            end

            def invoke(params : Hash(String, JSON::Any)) : Hash(String, JSON::Any)
              validate_params!(params)

              a = get_number(params["a"])
              b = get_number(params["b"])
              result = a + b

              {
                "result" => JSON::Any.new(result)
              }
            end

            private def get_number(value : JSON::Any) : Float64
              case value.raw
              when Int64
                value.as_i64.to_f64
              when Float64
                value.as_f.to_f64
              else
                raise ToolError.new("Parameter must be a number")
              end
            end
          end
        end
      end
    end
  end
end
