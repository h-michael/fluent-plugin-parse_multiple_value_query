require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'fluent/test'
unless ENV.key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval do |_obj|
    def method_missing(method, *args)
      # pass
    end
  end
  $log = nulllogger
end

require 'fluent/plugin/out_parse_multiple_value_query'

class Test::Unit::TestCase
end
