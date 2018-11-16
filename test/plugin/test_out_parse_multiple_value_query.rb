require 'helper'
require 'rr'
require 'timecop'
require 'fluent/plugin/out_parse_multiple_value_query'

class ParseMultipleValueQueryOutTest < Test::Unit::TestCase
  URL = 'http://example.com:80/?foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&multiple2[]='.freeze
  URL_INCLUDE_JP = 'http://example.com:80/?foo=bar&baz=qux&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3'.freeze
  ONLY_QUERY_STRING_TEST = 'foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3'.freeze
  REMOVE_EMPTY_KEY = 'http://example.com:80/?foo=bar&baz=qux&multiple[]=&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%AD%E3%82%B9%E3%82%AF&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B7%E3%82%A7%E3%83%B3%E3%82%AB%E3%83%BC&%E3%81%BE%E3%81%84%E3%81%91%E3%82%8B%5B%5D=%E3%82%B8%E3%83%A3%E3%82%AF%E3%82%BD%E3%83%B3&multiple2[]'.freeze
  WITHOUT_HOST = '/test/url?foo=bar&baz=qux&multiple[]=1&multiple[]=2&multiple[]=3&multiple2[]='.freeze

  def setup
    Fluent::Test.setup
    Timecop.freeze(@time)
  end

  teardown do
    Timecop.return
  end

  def create_driver(conf, tag)
    Fluent::Test::OutputTestDriver.new(
      Fluent::ParseMultipleValueQueryOutput, tag
    ).configure(conf)
  end

  def emit(conf, record, tag = 'test')
    d = create_driver(conf, tag)
    d.run { d.emit(record) }
    d.emits
  end

  def test_configure
    d = create_driver(%(
      key                url
      only_query_string  true
    ), 'test')

    assert_equal 'url',  d.instance.key
    assert_equal true,   d.instance.only_query_string
  end

  def test_filter_record
    conf = %(
      key            url
    )

    record = {
      'url' => URL
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'parsed.test', tag
      assert_equal URL,       emit_record['url']
      assert_equal 'bar',     emit_record['foo']
      assert_equal 'qux',     emit_record['baz']
      assert_equal %w[1 2 3], emit_record['multiple']
      assert_equal [''],      emit_record['multiple2']
    end
  end

  def test_jp_filter_record
    conf = %(
      key            url
    )

    record = {
      'url' => URL_INCLUDE_JP
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'parsed.test', tag
      assert_equal URL_INCLUDE_JP, emit_record['url']
      assert_equal 'bar',     emit_record['foo']
      assert_equal 'qux',     emit_record['baz']
      assert_equal %w[キスク シェンカー ジャクソン], emit_record['まいける']
    end
  end

  def test_only_query_string_filter_record
    conf = %(
      key                query_string
      only_query_string  true
    )

    record = {
      'query_string' => ONLY_QUERY_STRING_TEST
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'parsed.test', tag
      assert_equal ONLY_QUERY_STRING_TEST, emit_record['query_string']
      assert_equal 'bar',     emit_record['foo']
      assert_equal 'qux',     emit_record['baz']
      assert_equal %w[1 2 3], emit_record['multiple']
      assert_equal %w[キスク シェンカー ジャクソン], emit_record['まいける']
    end
  end

  def test_remove_empty_array
    conf = %(
      key                 url
      remove_empty_array  true
    )

    record = {
      'url' => REMOVE_EMPTY_KEY
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'parsed.test', tag
      assert_equal REMOVE_EMPTY_KEY,    emit_record['url']
      assert_equal 'bar',               emit_record['foo']
      assert_equal 'qux',               emit_record['baz']
      assert_equal nil,                 emit_record['multiple']
      assert_equal nil,                 emit_record['multiple2']
    end
  end

  def test_tag_prefix
    conf = %(
      key                 url
      tag_prefix          prefix.
    )

    record = {
      'url' => URL
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'prefix.test', tag
      assert_equal URL,       emit_record['url']
      assert_equal 'bar',     emit_record['foo']
      assert_equal 'qux',     emit_record['baz']
      assert_equal %w[1 2 3], emit_record['multiple']
    end
  end

  def test_sub_key
    conf = %(
      key                 url
      sub_key             url_parsed
    )

    record = {
      'url' => URL
    }

    emits = emit(conf, record)

    emits.each_with_index do |(_tag, _time, emit_record), _i|
      assert_equal URL,       emit_record['url']
      assert_equal 'bar',     emit_record['url_parsed']['foo']
      assert_equal 'qux',     emit_record['url_parsed']['baz']
      assert_equal %w[1 2 3], emit_record['url_parsed']['multiple']
    end
  end

  def test_without_host
    conf = %(
      key            url
      without_host   true
    )

    record = {
      'url' => WITHOUT_HOST
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, _time, emit_record), _i|
      assert_equal 'parsed.test', tag
      assert_equal 'bar',     emit_record['foo']
      assert_equal 'qux',     emit_record['baz']
      assert_equal %w[1 2 3], emit_record['multiple']
      assert_equal [''],      emit_record['multiple2']
    end
  end
end
