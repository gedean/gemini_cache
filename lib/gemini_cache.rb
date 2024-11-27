require 'faraday'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'base64'

require 'gemini_cache/configuration'
require 'gemini_cache/api_client'
require 'gemini_cache/item_extender'

# Module for interacting with Google's Gemini API cached contents
# @example Basic usage
#   GeminiCache.configure do |config|
#     config.api_key = 'your-api-key'
#   end
#
#   # Create a cache from text
#   cache = GeminiCache.create_from_text(
#     text: "Hello, world!",
#     display_name: "my-cache"
#   )
module GeminiCache
  # Custom error class for GeminiCache-specific errors
  class Error < StandardError; end

  class << self
    # Reads a local file and prepares it for the Gemini API
    # @param path [String] path to the local file
    # @param mime_type [String] MIME type of the file
    # @return [Hash] formatted data for the API
    def read_local_file(path:, mime_type:)
      { inline_data: { mime_type:, data: Base64.strict_encode64(File.read(path)) } }
    end

    # Reads a remote file and prepares it for the Gemini API
    # @param url [String] URL of the remote file
    # @param mime_type [String] MIME type of the file
    # @return [Hash] formatted data for the API
    def read_remote_file(url:, mime_type:)
      { inline_data: { mime_type:, data: Base64.strict_encode64(URI.open(url).read) } }
    end

    # Reads and parses HTML content from a URL
    # @param url [String] URL of the webpage
    # @param default_remover [Boolean] whether to remove script and style tags
    # @return [Nokogiri::HTML::Document] parsed HTML document
    def read_html(url:, default_remover: true)
      doc = Nokogiri::HTML(URI.open(url))
      %w[script style].each { |element| doc.css(element).each(&:remove) } if default_remover
      doc
    end

    # Creates a new cache in the Gemini API
    # @param parts [Array<Hash>] content parts to cache
    # @param display_name [String] unique display name for the cache
    # @param on_conflict [:raise_error, :get_existing] action to take if cache exists
    # @param model [String, nil] Gemini model to use
    # @param ttl [Integer, nil] time-to-live in seconds
    # @return [Hash] created cache data
    # @raise [Error] if cache already exists and on_conflict is :raise_error
    def create(parts:, display_name:, on_conflict: :raise_error, model: nil, ttl: nil)
      existing_cache = find_by_display_name(display_name:)
      
      if existing_cache
        case on_conflict
        when :raise_error
          raise Error, "Cache with display name '#{display_name}' already exists"
        when :get_existing
          return existing_cache
        end
      end

      content = {
        model: "models/#{model || configuration.default_model}",
        display_name: display_name,
        contents: [{ parts:, role: 'user' }],
        ttl: "#{ttl || configuration.default_ttl}s"
      }

      response = api_client.create_cache(content.to_json)
      find_by_name(name: response['name'])
    end

    # Creates a cache from plain text
    # @param text [String] text content to cache
    # @param options [Hash] additional options passed to #create
    # @return [Hash] created cache data
    def create_from_text(text:, **options)
      create(parts: [{ text: }], **options)
    end

    # Creates a cache from a webpage's content
    # @param url [String] URL of the webpage
    # @param options [Hash] additional options passed to #create
    # @return [Hash] created cache data
    def create_from_webpage(url:, **options)
      create_from_text(text: read_html(url:).inner_text, **options)
    end

    # Creates a cache from a local file
    # @param path [String] path to the local file
    # @param mime_type [String] MIME type of the file
    # @param options [Hash] additional options passed to #create
    # @return [Hash] created cache data
    def create_from_local_file(path:, mime_type:, **options)
      file_data = read_local_file(path: path, mime_type: mime_type)
      create(parts: [file_data], **options)
    end

    # Creates a cache from a remote file
    # @param url [String] URL of the remote file
    # @param mime_type [String] MIME type of the file
    # @param options [Hash] additional options passed to #create
    # @return [Hash] created cache data
    def create_from_remote_file(url:, mime_type:, **options)
      file_data = read_remote_file(url: url, mime_type: mime_type)
      create(parts: [file_data], **options)
    end

    # Lists all available caches
    # @return [Array<Hash>] list of caches with ItemExtender mixed in
    def list
      response = api_client.list_caches
      return [] if response.empty?

      response['cachedContents'].map { |item| item.extend(ItemExtender) }
    end

    # Finds a cache by its internal name
    # @param name [String] internal name of the cache
    # @return [Hash, nil] cache data if found, nil otherwise
    def find_by_name(name:)
      list.find { |item| item['name'].eql?(name) }
    end

    # Finds a cache by its display name
    # @param display_name [String] display name of the cache
    # @return [Hash, nil] cache data if found, nil otherwise
    def find_by_display_name(display_name:)
      list.find { |item| item['displayName'].eql?(display_name) }
    end

    # Updates an existing cache
    # @param name [String] internal name of the cache
    # @param content [Hash] new content for the cache
    # @return [Hash] updated cache data
    def update(name:, content:)
      api_client.update_cache(name, content)
    end

    # Deletes a specific cache
    # @param name [String] internal name of the cache to delete
    # @return [Boolean] true if successful
    def delete(name:)
      api_client.delete_cache(name)
      true
    end

    # Deletes all caches
    # @return [void]
    def delete_all
      list.each { |item| item.delete }
    end
    alias clear delete_all

    private

    def api_client
      @api_client ||= ApiClient.new
    end
  end
end
