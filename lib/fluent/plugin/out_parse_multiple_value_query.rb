module Fluent
  class ParseMultipleValueQueryOutput < Output
    Fluent::Plugin.register_output('parse_multipe_value_query', self)

    config_param :key,                :string
    config_param :tag_prefix,         :string, :default => 'parsed.'
    config_param :only_query_string,  :bool, :default => false
    config_param :remove_empty_array, :bool, :default => false

    def initialize
      super
      require 'rack'
    end

    # Define `log` method for v0.10.42 or earlier
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)
      es.each {|time, record|
        t = tag.dup
        new_record = parse_uri(record)

        t = @tag_prefix + t unless @tag_prefix.nil?

        Engine.emit(t, time, new_record)
      }
      chain.next
    rescue => e
      log.warn("out_parse_multiple_value_uri_query: error_class:#{e.class} error_message:#{e.message} tag:#{tag} es:#{es} bactrace:#{e.backtrace.first}")
    end

    def parse_uri(record)
      if record[key]
        if only_query_string
          record = parse_query_string(record,record[key])
          return record
        else
          query = URI.parse(record[key]).query
          record = parse_query_string(record, query)
          return record
        end
      end
    end

    def parse_query_string(record, query_string)
      begin
        parsed_query = Rack::Utils.parse_nested_query(query_string)
        parsed_query.each do |key, value|
          if value == ""
            record[key] = ""
          else
            if value.class == Array && remove_empty_array
              if value.empty? || value == [""] || value == [nil]
                record.delete(key)
              else
                record[key] = value
              end
            else
              record[key] = value
            end
          end
        end
      rescue => e
        log.warn("out_parse_multiple_value_uri_query: error_class:#{e.class} error_message:#{e.message} record:#{record} bactrace:#{e.backtrace.first}")
      end
      return record
    end
  end
end
