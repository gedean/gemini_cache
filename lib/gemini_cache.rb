require 'faraday'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'base64'

require 'gemini_cache/configuration'
require 'gemini_cache/api_client'
require 'gemini_cache/item_extender'

module GeminiCache
  class Error < StandardError; end

  class << self
    def parse_html(url:, default_remover: true)
      doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"))
      %w[script style].each { |element| doc.css(element).each(&:remove) } if default_remover
      doc
    end

    def read_local_file(path:, mime_type:)
      { inline_data: { mime_type:, data: Base64.strict_encode64(File.read(path)) } }
    end

    def read_remote_file(url:, mime_type:)
      { inline_data: { mime_type:, data: Base64.strict_encode64(URI.open(url).read) } }
    end

    def read_webpage_text(url:, default_remover: true) = { text: parse_html(url:, default_remover:).inner_text }

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

    def create_from_text(text:, **options) = create(parts: [{ text: }], **options)
    def create_from_webpage(url:, **options) = create_from_text(text: read_webpage_text(url:)[:text], **options)
    def create_from_local_file(path:, mime_type:, **options)
      file_data = read_local_file(path: path, mime_type: mime_type)
      create(parts: [file_data], **options)
    end

    def create_from_remote_file(url:, mime_type:, **options)
      file_data = read_remote_file(url: url, mime_type: mime_type)
      create(parts: [file_data], **options)
    end

    def list
      response = api_client.list_caches
      return [] if response.empty?

      response['cachedContents'].map { |item| item.extend(ItemExtender) }
    end

    def find_by_name(name:) = list.find { |item| item['name'].eql?(name) }
    def find_by_display_name(display_name:) = list.find { |item| item['displayName'].eql?(display_name) }

    def update(name:, content:) = api_client.update_cache(name, content)

    def delete(name:)
      api_client.delete_cache(name)
      true
    end

    def delete_all() = list.each { |item| item.delete }
    alias clear delete_all

    private

    def api_client
      @api_client ||= ApiClient.new
    end
  end
end
