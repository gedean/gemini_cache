# frozen_string_literal: true

module ItemExtender
  GEMINI_API_BASE_URL = 'https://generativelanguage.googleapis.com'
  DEFAULT_TIMEOUT = 300 # seconds
  ACCURATE_MODE_CONFIG = { temperature: 0, topP: 0, topK: 1 }.freeze

  def delete = GeminiCache.delete(name: self['name'])

  def ttl=(new_ttl)
    GeminiCache.update(name: self['name'], content: { ttl: "#{new_ttl}s" }.to_json)
  end
    
  def generate_content(contents:, generation_config: nil)
    response = api_client.post(generate_content_endpoint) do |req|
      req.params['key'] = ENV.fetch('GEMINI_API_KEY')
      req.body = build_request_body(contents, generation_config)
    end
    
    handle_response(response)
  rescue Faraday::Error => e
    raise GeminiAPIError, "Request failed: #{e.message}"
  end

  def single_prompt(prompt:, generation_config: :accurate_mode)
    config = generation_config.eql?(:accurate_mode) ? ACCURATE_MODE_CONFIG : generation_config
    
    generate_content(
      contents: [{ parts: [{ text: prompt }], role: 'user' }],
      generation_config: config
    ).content
  end
  
  private

  def api_client
    @api_client ||= Faraday.new(
      url: GEMINI_API_BASE_URL,
      headers: { 'Content-Type' => 'application/json' }
    ) do |f|
      f.options.timeout = DEFAULT_TIMEOUT
      f.options.open_timeout = DEFAULT_TIMEOUT
    end
  end

  def generate_content_endpoint
    "/v1beta/models/#{self['model'].split('/').last}:generateContent"
  end

  def build_request_body(contents, generation_config)
    {
      cached_content: self['name'],
      contents: contents,
      generation_config: generation_config
    }.compact.to_json
  end

  def handle_response(response)
    return parse_successful_response(response) if response.status == 200

    raise GeminiAPIError, "Content generation failed: #{response.body}"
  end

  def parse_successful_response(response)
    resp = JSON.parse(response.body)
    def resp.content
      dig('candidates', 0, 'content', 'parts', 0, 'text')
    end
    resp
  end
end

class GeminiAPIError < StandardError; end
