module ItemExtender
  def delete = GeminiCache.delete(name: self['name'])

  def ttl=(new_ttl)
    GeminiCache.update(name: self['name'], content: { ttl: "#{new_ttl}s" })
  end
  
  def generate_content(contents:, generation_config: nil)
    conn = Faraday.new(
      url: 'https://generativelanguage.googleapis.com',
      headers: { 'Content-Type' => 'application/json' }
    ) do |f|
      f.options.timeout = 300        # timeout em segundos para a requisição completa
      f.options.open_timeout = 300   # timeout em segundos para abrir a conexão
    end

    body = {
      cached_content: self['name'],
      contents:
    }

    body[:generation_config] = generation_config if !generation_config.nil?

    response = conn.post("/v1beta/models/#{self['model'].split('/').last}:generateContent") do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
      req.body = body.to_json
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
    
  def single_prompt(prompt:, generation_config: :accurate_mode)
    # accurate_mode: less creative, more accurate
    generation_config = { temperature: 0, topP: 0, topK: 1 } if generation_config.eql?(:accurate_mode)
    generate_content(contents: [{ parts: [{ text: prompt }], role: 'user' }], generation_config:).content
  end      
end
