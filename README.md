# GeminiCache

GeminiCache is a Ruby library for interacting with Google Gemini's Cache API. It provides a simple interface to create, manage, and manipulate content caches for use with Gemini AI models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gemini_cache'
```

And then execute:

```bash
$ bundle install
```

Or install it manually:

```bash
$ gem install gemini_cache
```

## Configuration

Before using the library, you need to configure your Google Gemini API key. You can do this in two ways:

### 1. Using environment variables

```bash
export GEMINI_API_KEY='your_api_key_here'
```

### 2. Using the configuration block

```ruby
GeminiCache.configure do |config|
  config.api_key = 'your_api_key_here'
  config.timeout = 30 # optional, timeout in seconds
  config.cache_dir = '/path/to/cache' # optional, local cache directory
end
```

## Basic Usage

### Initializing the Client

```ruby
cache = GeminiCache::Client.new
```

### Basic Operations

#### Storing data in cache

```ruby
# Store a value with a key
cache.set('my_key', 'my_value')

# Store with expiration time (in seconds)
cache.set('my_key', 'my_value', expires_in: 3600)
```

#### Retrieving data from cache

```ruby
# Retrieve a value
value = cache.get('my_key')

# Retrieve with default value if key doesn't exist
value = cache.get('my_key', default: 'default_value')
```

#### Removing data from cache

```ruby
# Remove a specific key
cache.delete('my_key')

# Clear entire cache
cache.clear
```

## Advanced Usage

### Batch Operations

```ruby
# Store multiple values
cache.set_multi({
  'key1' => 'value1',
  'key2' => 'value2'
})

# Retrieve multiple values
values = cache.get_multi(['key1', 'key2'])
```

### Block Caching

```ruby
# Execute block only if value is not in cache
result = cache.fetch('my_key') do
  # computationally intensive code here
  computed_result
end
```

## Gemini AI Integration

### Caching AI Responses

```ruby
# Basic AI response caching
gemini = Google::Cloud::Gemini.new
cache = GeminiCache::Client.new

response = cache.fetch('gemini_query_key') do
  gemini.generate_content('What is the meaning of life?')
end
```

### Model-Specific Caching

```ruby
# Create separate caches for different models
pro_cache = GeminiCache::Client.new(namespace: 'gemini-pro')
vision_cache = GeminiCache::Client.new(namespace: 'gemini-vision')

# Cache text generation results
text_response = pro_cache.fetch('text_query') do
  gemini_pro.generate_content('Write a poem about coding')
end

# Cache vision analysis results
vision_response = vision_cache.fetch('image_analysis') do
  gemini_vision.analyze_image(image_data)
end
```

### Caching with Parameters

```ruby
# Cache with different parameters
def get_ai_response(prompt, temperature: 0.7)
  cache_key = "gemini_#{prompt}_#{temperature}"
  
  cache.fetch(cache_key, expires_in: 24.hours) do
    gemini.generate_content(
      prompt,
      temperature: temperature
    )
  end
end

# Usage
response1 = get_ai_response("Tell me a joke", temperature: 0.8)
response2 = get_ai_response("Tell me a joke", temperature: 0.3)
```

### Handling Large Responses

```ruby
# Cache large responses with compression
cache.fetch('large_response', compress: true) do
  gemini.generate_content('Write a long story')
end

# Cache with size limits
cache.fetch('limited_response', max_size: 1.megabyte) do
  gemini.generate_content('Generate large content')
end
```

## Error Handling

```ruby
begin
  cache.get('my_key')
rescue GeminiCache::ConnectionError => e
  puts "Connection error: #{e.message}"
rescue GeminiCache::TimeoutError => e
  puts "Timeout exceeded: #{e.message}"
rescue GeminiCache::CacheSizeError => e
  puts "Cache size limit exceeded: #{e.message}"
end
```

## Performance Tips

- Use namespaces to organize different types of cached content
- Set appropriate expiration times based on content volatility
- Implement cache warming for frequently accessed content
- Monitor cache hit rates and adjust strategies accordingly

```ruby
# Cache warming example
def warm_cache
  common_queries.each do |query|
    cache.fetch(query, force: false) do
      gemini.generate_content(query)
    end
  end
end
```

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a new Pull Request

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).