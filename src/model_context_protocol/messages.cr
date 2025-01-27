require "json"

module ModelContextProtocol
  module Messages
    # Error codes for MCP responses
    module ErrorCodes
      SERVER_ERROR_START = -32099
      SERVER_ERROR_END = -32000
      PARSE_ERROR = -32700
      INVALID_REQUEST = -32600
      METHOD_NOT_FOUND = -32601
      INVALID_PARAMS = -32602
      INTERNAL_ERROR = -32603
    end

    # Error information for MCP responses
    class Error
      include JSON::Serializable

      getter code : Int32
      getter message : String
      getter data : JSON::Any?

      def initialize(@code, @message, @data = nil)
      end

      def self.from_json_object(object : JSON::Any) : Error
        code = object["code"].as_i
        message = object["message"].as_s
        data = object["data"]?

        new(code, message, data)
      end
    end

    # MCP Request message
    class Request
      include JSON::Serializable

      getter id : String | Int64
      getter method : String
      getter params : Hash(String, JSON::Any)?

      def initialize(@id, @method, params : Hash(String, _)? = nil)
        @params = params.try do |p|
          result = {} of String => JSON::Any
          p.each do |k, v|
            result[k] = case v
            when JSON::Any
              v
            when String
              JSON::Any.new(v)
            when Int
              JSON::Any.new(v.to_i64)
            when Float
              JSON::Any.new(v.to_f64)
            when Bool
              JSON::Any.new(v)
            when Hash
              JSON::Any.new(v.transform_values { |hv| hv.is_a?(JSON::Any) ? hv : JSON::Any.new(hv) })
            when Array
              JSON::Any.new(v.map { |av| av.is_a?(JSON::Any) ? av : JSON::Any.new(av) })
            when Nil
              JSON::Any.new(nil)
            else
              JSON::Any.new(v.to_s)
            end
          end
          result
        end
      end

      def self.from_json_object(object : JSON::Any) : Request
        id = object["id"].raw.as(String | Int64)
        method = object["method"].as_s
        params = object["params"]?.try(&.as_h)

        new(id, method, params)
      end
    end

    # MCP Response message
    class Response
      include JSON::Serializable

      getter id : String | Int64
      getter result : Hash(String, JSON::Any)?
      getter error : Error?

      def initialize(@id, @result = nil, @error = nil)
      end

      def self.from_json_object(object : JSON::Any) : Response
        id = object["id"].raw.as(String | Int64)
        result = object["result"]?.try(&.as_h)
        error = object["error"]?.try { |e| Error.from_json_object(e) }

        new(id, result, error)
      end
    end

    # MCP Notification message
    class Notification
      include JSON::Serializable

      getter method : String
      getter params : Hash(String, JSON::Any)?

      def initialize(@method, @params = nil)
      end

      def self.from_json_object(object : JSON::Any) : Notification
        method = object["method"].as_s
        params = object["params"]?.try(&.as_h)

        new(method, params)
      end
    end
  end
end
