require "base64"
require "json"

module ModelContextProtocol
  module Server
    module Utilities
      # Utility class for handling pagination in MCP
      class Pagination(T)
        class Cursor
          include JSON::Serializable
          
          property offset : Int32
          property total : Int32

          def initialize(@offset = 0, @total = 0)
          end

          def to_s : String
            Base64.strict_encode(to_json)
          end

          def self.from_string(cursor : String) : Cursor
            from_json(String.new(Base64.decode(cursor)))
          rescue
            new # Return a new cursor if parsing fails
          end
        end

        class Page(T)
          include JSON::Serializable
          
          property items : Array(T)
          property next_cursor : String?

          def initialize(@items, @next_cursor = nil)
          end
        end

        private getter items : Array(T)
        private getter page_size : Int32

        def initialize(@items, @page_size = 50)
        end

        # Get a page of results starting from the given cursor
        def get_page(cursor_str : String? = nil) : Page(T)
          cursor = cursor_str ? Cursor.from_string(cursor_str) : Cursor.new
          
          start_idx = cursor.offset
          end_idx = Math.min(start_idx + @page_size, @items.size)
          
          page_items = @items[start_idx...end_idx]
          
          next_cursor = if end_idx < @items.size
            Cursor.new(end_idx, @items.size).to_s
          end

          Page.new(page_items, next_cursor)
        end

        # Create a paginated response for a list request
        def self.paginate(items : Array(T), cursor : String? = nil, page_size : Int32 = 50) : Page(T)
          new(items, page_size).get_page(cursor)
        end
      end
    end
  end
end
