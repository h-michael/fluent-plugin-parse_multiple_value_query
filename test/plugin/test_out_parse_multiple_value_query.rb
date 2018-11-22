require 'helper'
require 'rr'
require 'pry-byebug'
require 'fluent/plugin/out_parse_multiple_value_query'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'

class ParseMultipleValueQueryOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  URL = 'http://example.com:80/?foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&multiple2[]='.freeze
  URL_INCLUDE_JP = 'http://example.com:80/?foo=bar&baz=qux&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3'.freeze
  ONLY_QUERY_STRING_TEST = 'foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3'.freeze
  REMOVE_EMPTY_KEY = 'http://example.com:80/?foo=bar&baz=qux&multiple[]=&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3&multiple2[]'.freeze
  WITHOUT_HOST = '/test/url?foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&multiple2[]='.freeze

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ParseMultipleValueQueryOutput).configure(conf)
  end

  def setup
    Fluent::Test.setup
  end

  sub_test_case 'configure' do
    test 'configure' do
      d = create_driver(%(
      key url
      only_query_string true
      ))

      assert_equal 'url', d.instance.key
      assert_equal true,  d.instance.only_query_string
    end
  end

  sub_test_case 'emit events' do
    test 'filter record' do
      d = create_driver(%(
        key url
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => URL })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed.test', event.first
      assert_equal URL,           event[2]['url']
      assert_equal 'bar',         event[2]['foo']
      assert_equal 'qux',         event[2]['baz']
      assert_equal %w[1 2 3],     event[2]['multiple']
      assert_equal [''],          event[2]['multiple2']
    end

    test 'jp filter record' do
      d = create_driver(%(
        key url
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => URL_INCLUDE_JP })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed.test',                    event.first
      assert_equal URL_INCLUDE_JP,                   event[2]['url']
      assert_equal 'bar',                            event[2]['foo']
      assert_equal 'qux',                            event[2]['baz']
      assert_equal %w[キスク シェンカー ジャクソン], event[2]['まいける']
    end

    test 'only query string filter record' do
      d = create_driver(%(
        key query_string
        only_query_string true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'query_string' => ONLY_QUERY_STRING_TEST })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed.test',                    event.first
      assert_equal ONLY_QUERY_STRING_TEST,           event[2]['query_string']
      assert_equal 'bar',                            event[2]['foo']
      assert_equal 'qux',                            event[2]['baz']
      assert_equal %w[1 2 3],                        event[2]['multiple']
      assert_equal %w[キスク シェンカー ジャクソン], event[2]['まいける']
    end

    test 'remove empty array' do
      d = create_driver(%(
        key url
        remove_empty_array  true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => REMOVE_EMPTY_KEY })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed.test',    event.first
      assert_equal REMOVE_EMPTY_KEY, event[2]['url']
      assert_equal 'bar',            event[2]['foo']
      assert_equal 'qux',            event[2]['baz']
      assert_equal nil,              event[2]['multiple']
      assert_equal nil,              event[2]['multiple2']
    end

    test 'tag prefix' do
      d = create_driver(%(
        key url
        tag_prefix prefix.
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => URL })
      end
      events = d.events
      event = events.first

      assert_equal 'prefix.test', event.first
      assert_equal URL,           event[2]['url']
      assert_equal 'bar',         event[2]['foo']
      assert_equal 'qux',         event[2]['baz']
      assert_equal %w[1 2 3],     event[2]['multiple']
    end

    test 'sub key' do
      d = create_driver(%(
        key url
        sub_key url_parsed
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => URL })
      end
      events = d.events
      event = events.first

      assert_equal URL,           event[2]['url']
      assert_equal 'bar',         event[2]['url_parsed']['foo']
      assert_equal 'qux',         event[2]['url_parsed']['baz']
      assert_equal %w[1 2 3],     event[2]['url_parsed']['multiple']
    end

    test 'without host' do
      d = create_driver(%(
        key url
        without_host true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'url' => WITHOUT_HOST })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed.test', event.first
      assert_equal 'bar',         event[2]['foo']
      assert_equal 'qux',         event[2]['baz']
      assert_equal %W[1 2 3],     event[2]['multiple']
      assert_equal [''],          event[2]['multiple2']
    end
  end
end
