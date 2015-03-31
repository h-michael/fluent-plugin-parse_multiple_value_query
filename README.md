# Fluent::Plugin::ParseMultipleValueQuery

Fluentd plugin to parse URL query parameters with Rack::Utils
I think most of the type of query can be parsed by [fluent-plugin-extract_query_params](https://github.com/kentaro/fluent-plugin-extract_query_params).

I wanted to be able to parse multiple value query string like this.
```
input
"test" {
  "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5"
}

output
    "test" {
      "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5",
      "key1": ["value1", "value2", "value3"],
      "key2": ["value4", "value5"],
      "key3": [""]
    }
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-parse_multiple_value_query'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-parse_multiple_value_query

## Usage

default usage
```
<match foo.**>
  type parse_multiple_value_query
  key  url
</match>

input
"test" {
  "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]="
}

output
    "parsed.test" {
      "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]=",
      "key1": ["value1", "value2", "value3"],
      "key2": ["value4", "value5"],
      "key3": [""]
    }
```

change tag prefix (default tag prefix is "parsed.")
```
<match foo.**>
  type parse_multiple_value_query
  key  url
  tag_prefix changed.
  
</match>

input
"test" {
  "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]="
}

output
    "changed.test" {
      "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]=",
      "key1": ["value1", "value2", "value3"],
      "key2": ["value4", "value5"],
      "key3": [""]
    }
```

If target value is only query string without uri.
```
<match foo.**>
  type               parse_multiple_value_query
  only_query_string  true
  key                query_string
</match>

input
"test" {
  "query_string": "key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]="
}

output
    "parsed.test" {
      "query_string": "key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]=",
      "key1": ["value1", "value2", "value3"],
      "key2": ["value4", "value5"],
      "key3": [""]
    }
```

If you want remove value that is like [] or [""] from record.
```
<match foo.**>
  type                parse_multiple_value_query
  key                 url
  remove_empty_array  true
</match>

input
"test" {
  "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]="
}

output
    "parsed.test" {
      "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]=",
      "key1": ["value1", "value2", "value3"],
      "key2": ["value4", "value5"]
    }
```

If you want create sub key with parsed data.
```
<match foo.**>
  type                parse_multiple_value_query
  key                 url
  sub_key             url_parsed
</match>

input
"test" {
  "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]="
}

output
    "parsed.test" {
      "url": "http://example.com?key1[]=value1&key1[]=value2&key1[]=value3&key2[]=value4&key2[]=value5&key3[]=",
      "url_parsed": {
        "key1": ["value1", "value2", "value3"],
        "key2": ["value4", "value5"],
        "key3": [""]
      }
    }
```

## Option Parameters

### key :String
key is used to point a key thad value contains URL string or query string.

### tag_prefix :String
Added tag prefix.
Default value is "parsed."

### only_query_string :Bool
Parsed target isn't URL but only query string.
You must be this option setting true.
Default value is false.

### remove_empty_array :Bool
You want to remove parsed value that has [] or [""] or [nil].
You must be this option setting true.
Default value is false.

### sub_key :String
You want to put parsed data into separate key.
Default value is false.

## Relative
 - [fluent-plugin-extract_query_params](https://github.com/kentaro/fluent-plugin-extract_query_params)

## Change log
See [CHANGELOG.md](https://github.com/h-michael-z/fluent-plugin-parse_multiple_value_query/blob/master/CHANGELOG.md) for details.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fluent-plugin-parse_multiple_value_query/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
