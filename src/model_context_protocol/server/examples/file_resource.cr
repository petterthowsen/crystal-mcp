require "../resource"

module ModelContextProtocol
  module Server
    module Examples
      # Example implementation of a file-based resource
      class FileResource < Resource
        property path : String

        def initialize(@path)
          metadata = {
            "type" => JSON::Any.new("file"),
            "path" => JSON::Any.new(@path),
            "size" => JSON::Any.new(File.size(@path).to_i64)
          }
          super("file://#{@path}", metadata)
        end

        def read : String
          File.read(@path)
        rescue ex
          raise ResourceError.new("Failed to read file: #{ex.message}")
        end

        def subscribe : Bool
          # Example implementation could watch file for changes
          false
        end
      end
    end
  end
end
