require 'faraday'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'base64'

require 'gemini_cache/item_extender'

module GeminiCache
  def self.read_local_file(path:, mime_type:) = { inline_data: { mime_type:, data: Base64.strict_encode64(File.read(path)) } } 
  def self.read_remote_file(url:, mime_type:) = { inline_data: { mime_type:, data: Base64.strict_encode64(URI.open(url).read) } } 
  def self.read_html(url:, default_remover: true)
    doc = Nokogiri::HTML(URI.open(url))
    %w[script style].each { |element| doc.css(element).each(&:remove) } if default_remover

    doc
  end

  def self.create(parts:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 300)
    raise "Cache name already exist: '#{display_name}'" if GeminiCache.get_by_display_name(display_name:)

    content = {
      model: "models/#{model}",
      display_name:,
      contents: [parts:, role: 'user'],
      ttl: "#{ttl}s"
    }.to_json
  
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    )
  
    response = conn.post('/v1beta/cachedContents') do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
      req.body = content
    end
  
    return get_by_name(name: JSON.parse(response.body)['name']) if response.status == 200
  
    raise "Erro ao criar cache: #{response.status} - #{response.body}"
  rescue Faraday::Error => e
    raise "Erro na requisição: #{e.message}"
  end

  def self.create_from_text(text:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 300)
    GeminiCache.create(parts: [{ text: }], display_name:, model:, ttl:)
  end

  def self.create_from_webpage(url:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 300)
    create_from_text(text: GeminiCache.read_html(url:).inner_text, display_name:, model:, ttl:)
  end

  def self.create_from_local_file(path:, mime_type:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 300)
    GeminiCache.create(parts: GeminiCache.read_local_file(path:, mime_type:), display_name:, model:, ttl:)
  end

  def self.create_from_remote_file(url:, mime_type:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 300)
    GeminiCache.create(parts: GeminiCache.read_remote_file(url:, mime_type:), display_name:, model:, ttl:)
  end

  def self.get_by_name(name: nil) = GeminiCache.list.find { |item| item['name'].eql? name }
  def self.get_by_display_name(display_name: nil) = GeminiCache.list.find { |item| item['displayName'].eql? display_name }

  def self.list
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    )

    response = conn.get("/v1beta/cachedContents") do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
    end
    
    return [] if JSON.parse(response.body).empty?

    JSON.parse(response.body)['cachedContents'].map { |item| item.extend(ItemExtender) }

  rescue Faraday::Error => e
    raise "Erro na requisição: #{e.message}"
  end
  
  def self.update(name:, content:)
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    )

    response = conn.patch("/v1beta/#{name}") do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
      req.body = content.to_json
    end

    return JSON.parse(response.body) if response.status == 200
    
    raise "Erro ao atualizar cache: #{response.body}"
  rescue Faraday::Error => e
    raise "Erro na requisição: #{e.message}"
  end

  def self.delete(name:)
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    )

    response = conn.delete("/v1beta/#{name}") do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
    end

    return true if response.status == 200
    
    raise "Erro ao deletar cache: #{response.body}"
  rescue Faraday::Error => e
    raise "Erro na requisição: #{e.message}"
  end

  def self.delete_all
    GeminiCache.list.each { |item| item.delete }
  end

  class << self
    alias clear delete_all
  end
end
