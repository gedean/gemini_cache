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

  def self.parse_html(url:, default_remover: true)
    doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0'))
    %w[script style].each { doc.css(it).remove } if default_remover
    doc
  end

  def self.read_local_file(path:, mime_type:)
    { inline_data: { mime_type:, data: Base64.strict_encode64(File.read(path)) } }
  end

  def self.read_remote_file(url:, mime_type:)
    { inline_data: { mime_type:, data: Base64.strict_encode64(URI.open(url).read) } }
  end

  def self.read_webpage_text(url:, default_remover: true)
    { text: parse_html(url:, default_remover:).inner_text }
  end

  def self.create(parts:, display_name:, on_conflict: :raise_error, model: nil, ttl: nil)
    existing_cache = find_by_display_name(display_name:)
    
    if existing_cache
      return existing_cache if on_conflict == :get_existing
      raise Error, "Cache with display name '#{display_name}' already exists" if on_conflict == :raise_error
    end

    content = {
      model: "models/#{model || configuration.default_model}",
      display_name:,
      contents: [{ parts:, role: 'user' }],
      ttl: "#{ttl || configuration.default_ttl}s"
    }

    response = api_client.create_cache(content.to_json)
    find_by_name(name: response['name'])
  end

  def self.create_from_text(text:, **options)
    create(parts: [{ text: }], **options)
  end

  def self.create_from_webpage(url:, **options)
    create_from_text(text: read_webpage_text(url:)[:text], **options)
  end

  def self.create_from_local_file(path:, mime_type:, **options)
    create(parts: [read_local_file(path:, mime_type:)], **options)
  end

  def self.create_from_remote_file(url:, mime_type:, **options)
    create(parts: [read_remote_file(url:, mime_type:)], **options)
  end

  def self.list
    response = api_client.list_caches
    return [] if response.empty?

    response['cachedContents'].map { it.extend(ItemExtender) }
  end

  def self.find_by_name(name:)
    list.find { it['name'] == name }
  end

  def self.find_by_display_name(display_name:)
    list.find { it['displayName'] == display_name }
  end

  def self.update(name:, content:)
    api_client.update_cache(name, content)
  end

  def self.delete(name:)
    api_client.delete_cache(name)
    true
  end

  def self.delete_all
    list.each(&:delete)
  end

  class << self
    alias clear delete_all

    private

    def api_client
      @api_client ||= ApiClient.new
    end
  end
end
