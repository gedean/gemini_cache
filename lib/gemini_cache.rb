require 'faraday'
require 'json'

module GeminiCache
  def self.create(contents:, display_name:, model: 'gemini-1.5-flash-8b', ttl: 600)
    content = {
      model: "models/#{model}",
      display_name:,
      contents:,
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
  
    return JSON.parse(response.body) if response.status == 200
  
    raise "Erro ao criar cache: #{response.status} - #{response.body}"
  rescue Faraday::Error => e
    raise "Erro na requisição: #{e.message}"
  end

  def self.get(name: nil, display_name: nil)
    raise 'Nome do cache ou display name é obrigatório' if name.nil? && display_name.nil?
    raise 'Nome do cache e display name não podem ser informados juntos' if !name.nil? && !display_name.nil?
    
    return GeminiCache.list.find { |item| item['name'].eql? name } if !name.nil?
    return GeminiCache.list.find { |item| item['displayName'].eql? display_name } if !display_name.nil?
  end

  def self.list
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    )

    response = conn.get("/v1beta/cachedContents") do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
    end
    
    return [] if JSON.parse(response.body).empty?

    JSON.parse(response.body)['cachedContents'].map do |item|
      def item.delete = GeminiCache.delete(name: self['name'])
      def item.set_ttl(ttl = 120) = GeminiCache.update(name: self['name'], content: { ttl: "#{ttl}s" })

      def item.generate_content(contents:)
        conn = Faraday.new(
          url: 'https://generativelanguage.googleapis.com',
          headers: { 'Content-Type' => 'application/json' }
        ) do |f|
          f.options.timeout = 300        # timeout em segundos para a requisição completa
          f.options.open_timeout = 300   # timeout em segundos para abrir a conexão
        end

        response = conn.post("/v1beta/models/#{self['model'].split('/').last}:generateContent") do |req|
          req.params['key'] = ENV.fetch('GEMINI_API_KEY')
          req.body = {
            cached_content: self['name'],
            contents:
          }.to_json
        end
        
        if response.status == 200
          resp = JSON.parse(response.body)
          def resp.content = dig('candidates', 0, 'content', 'parts', 0, 'text')
          return resp
        end

        raise "Erro ao gerar conteúdo: #{response.body}"
      rescue Faraday::Error => e
        raise "Erro na requisição: #{e.message}"
      end
      
      def item.single_prompt(prompt:) = generate_content(contents: [{ parts: [{ text: prompt }], role: 'user' }]).content

      item
    end

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
