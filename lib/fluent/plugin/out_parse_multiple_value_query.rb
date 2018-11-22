require 'fluent/plugin/output'

module Fluent::Plugin
  class ParseMultipleValueQueryOutput < Fluent::Plugin::Output
    Fluent::Plugin.register_output('parse_multiple_value_query', self)

    config_param :key,                :string
    config_param :tag_prefix,         :string, default: 'parsed.'
    config_param :only_query_string,  :bool, default: false
    config_param :remove_empty_array, :bool, default: false
    config_param :sub_key,            :string, default: nil
    config_param :without_host,       :bool, default: false

    helpers :event_emitter

    def initialize
      super
      require 'rack'
    end

    # Define `log` method for v0.10.42 or earlier
    define_method('log') { $log } unless method_defined?(:log)

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def multi_workers_ready?
      true
    end

    def process(tag, es)
      es.each do |time, record|
        t = tag.dup
        new_record = parse_uri(record)

        t = @tag_prefix + t unless @tag_prefix.nil?

        router.emit(t, time, new_record)
      end
      chain.next
    rescue StandardError => e
      log.warn("out_parse_multiple_value_uri_query: error_class:#{e.class} error_message:#{e.message} tag:#{tag} es:#{es} bactrace:#{e.backtrace.first}")
    end

    def parse_uri(record)
      return unless record[key]
      if only_query_string
        parse_query_string(record, record[key])
      else
        url = without_host ? "http://example.com#{record[key]}" : record[key]

        query = URI.parse(url).query
        parse_query_string(record, query)
      end
    end

    def parse_query_string(record, query_string)
      begin
        target = sub_key ? (record[sub_key] ||= {}) : record

        parsed_query = Rack::Utils.parse_nested_query(query_string)
        parsed_query.each do |key, value|
          if value == ''
            target[key] = ''
          else
            if value.class == Array && remove_empty_array
              if value.empty? || value == [''] || value == [nil]
                target.delete(key)
              else
                target[key] = value
              end
            else
              target[key] = value
            end
          end
        end
      rescue StandardError => e
        log.warn("out_parse_multiple_value_uri_query: error_class:#{e.class} error_message:#{e.message} record:#{record} bactrace:#{e.backtrace.first}")
      end
      record
    end
  end
end
