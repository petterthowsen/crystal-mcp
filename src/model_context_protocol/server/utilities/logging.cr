require "json"
require "log"

module ModelContextProtocol
  module Server
    module Utilities
      # Utility class for MCP logging
      class Logging
        Log = ::Log.for(self)

        enum Level
          Debug
          Info
          Notice
          Warning
          Error
          Critical
          Alert
          Emergency

          def to_s : String
            super.downcase
          end

          def log_message(logger : ::Log, message : String)
            case self
            when Debug
              logger.debug { message }
            when Info
              logger.info { message }
            when Notice
              logger.notice { message }
            when Warning
              logger.warn { message }
            when Error
              logger.error { message }
            when Critical, Alert, Emergency
              logger.fatal { message }
            else
              logger.info { message }
            end
          end

          def to_log_severity : ::Log::Severity
            case self
            when Debug
              ::Log::Severity::Debug
            when Info
              ::Log::Severity::Info
            when Notice
              ::Log::Severity::Notice
            when Warning
              ::Log::Severity::Warn
            when Error
              ::Log::Severity::Error
            when Critical, Alert, Emergency
              ::Log::Severity::Fatal
            else
              ::Log::Severity::Info
            end
          end

          def self.from_string(level : String) : Level
            parse(level.upcase)
          rescue
            Info # Default to Info if parsing fails
          end
        end

        class LogMessage
          include JSON::Serializable
          
          property level : String
          property logger : String?
          property data : Hash(String, JSON::Any)

          def initialize(@level, @logger = nil, @data = {} of String => JSON::Any)
          end

          def to_json_params : Hash(String, JSON::Any)
            params = {
              "level" => JSON::Any.new(@level)
            }

            if logger = @logger
              params["logger"] = JSON::Any.new(logger)
            end

            @data.each do |key, value|
              params[key] = value
            end

            params
          end
        end

        private getter transport : Transport::Base?
        private property min_level : Level

        def initialize(@transport = nil, @min_level = Level::Info)
        end

        # Set the transport after initialization
        def transport=(transport : Transport::Base)
          @transport = transport
        end

        # Set the minimum log level
        def set_level(level : String) : Nil
          @min_level = Level.from_string(level)
        end

        # Send a log message if it meets the minimum level
        def log(level : Level, message : String, logger : String? = nil, data : Hash(String, JSON::Any)? = nil) : Nil
          return if level.value < @min_level.value

          log_data = data || {} of String => JSON::Any
          log_data["message"] = JSON::Any.new(message)

          log_message = LogMessage.new(
            level: level.to_s,
            logger: logger,
            data: log_data
          )

          if transport = @transport
            notification = Messages::Notification.new(
              "notifications/message",
              log_message.to_json_params
            )

            transport.send_notification(notification)
          else
            # Fallback to standard logging if no transport is set
            level.log_message(Log, message)
          end
        end

        {% for level in %w(debug info notice warning error critical alert emergency) %}
          def {{level.id}}(message : String, logger : String? = nil, data : Hash(String, JSON::Any)? = nil) : Nil
            log(Level::{{level.camelcase.id}}, message, logger, data)
          end
        {% end %}
      end
    end
  end
end
