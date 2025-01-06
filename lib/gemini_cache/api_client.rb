module GeminiCache
  class ApiClient
    class ApiError < StandardError; end

    def initialize
      @conn = Faraday.new(
        url: GeminiCache.configuration.api_base_url,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    def create_cache(content)
      response = @conn.post('/v1beta/cachedContents') do |req|
        req.params['key'] = api_key
        req.body = content
      end

      handle_response(response)
    end

    def list_caches
      response = @conn.get('/v1beta/cachedContents') do |req|
        req.params['key'] = api_key
      end

      handle_response(response)
    end

    def update_cache(name, content)
      response = @conn.patch("/v1beta/#{name}") do |req|
        req.params['key'] = api_key
        req.body = content
      end

      handle_response(response)
    end

    def delete_cache(name)
      response = @conn.delete("/v1beta/#{name}") do |req|
        req.params['key'] = api_key
      end

      handle_response(response)
    end

    private

    def api_key
      GeminiCache.configuration.api_key || ENV.fetch('GEMINI_API_KEY')
    end

    def handle_response(response)
      return JSON.parse(response.body) if response.status == 200
      
      error_message = JSON.parse(response.body)['error'] rescue response.body
      raise ApiError, "API request failed (#{response.status}): #{error_message}"
    rescue Faraday::Error => e
      raise ApiError, "Network error: #{e.message}"
    end
  end
end
