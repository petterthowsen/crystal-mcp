require "../tool"

module ModelContextProtocol
  module Server
    module Examples
      # Example implementation of a shell command execution tool
      class ShellTool < Tool
        def initialize
          parameters = {
            "command" => JSON::Any.new({
              "type" => "string",
              "description" => "Shell command to execute"
            }),
            "workingDirectory" => JSON::Any.new({
              "type" => "string",
              "description" => "Working directory for command execution"
            })
          }
          super(
            name: "shell",
            description: "Execute shell commands",
            parameters: parameters,
            required_parameters: ["command"]
          )
        end

        def invoke(params : Hash(String, JSON::Any)) : Hash(String, JSON::Any)
          validate_params!(params)

          command = params["command"].as_s
          working_dir = params["workingDirectory"]?.try(&.as_s) || Dir.current

          output = IO::Memory.new
          error = IO::Memory.new

          status = Process.run(
            command,
            shell: true,
            output: output,
            error: error,
            chdir: working_dir
          )

          {
            "status" => JSON::Any.new(status.exit_code),
            "output" => JSON::Any.new(output.to_s),
            "error" => JSON::Any.new(error.to_s)
          }
        rescue ex
          raise ToolError.new("Failed to execute command: #{ex.message}")
        end

        private def validate_params!(params : Hash(String, JSON::Any)) : Nil
          super(params)
          
          command = params["command"]?.try(&.as_s)
          raise ToolError.new("Command must not be empty") if command.try(&.empty?)

          if dir = params["workingDirectory"]?.try(&.as_s)
            raise ToolError.new("Working directory does not exist") unless Dir.exists?(dir)
          end
        end
      end
    end
  end
end
