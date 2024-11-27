module GeminiCache
  # Client for making HTTP requests to the Gemini API
  class ApiClient
    # Error class for API-related errors
    class ApiError < StandardError; end

    # Initializes a new API client
    def initialize
      @conn = Faraday.new(
        url: GeminiCache.configuration.api_base_url,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    # Creates a new cache
    # @param content [String] JSON string of cache content
    # @return [Hash] API response
    # @raise [ApiError] if the request fails
    def create_cache(content)
      response = @conn.post('/v1beta/cachedContents') do |req|
        req.params['key'] = api_key
        req.body = content
      end

      handle_response(response)
    end

    # Lists all caches
    # @return [Hash] API response
    # @raise [ApiError] if the request fails
    def list_caches
      response = @conn.get('/v1beta/cachedContents') do |req|
        req.params['key'] = api_key
      end

      handle_response(response)
    end

    # Updates an existing cache
    # @param name [String] cache name
    # @param content [String] JSON string of new content
    # @return [Hash] API response
    # @raise [ApiError] if the request fails
    def update_cache(name, content)
      response = @conn.patch("/v1beta/#{name}") do |req|
        req.params['key'] = api_key
        req.body = content
      end

      handle_response(response)
    end

    # Deletes a cache
    # @param name [String] cache name
    # @return [Hash] API response
    # @raise [ApiError] if the request fails
    def delete_cache(name)
      response = @conn.delete("/v1beta/#{name}") do |req|
        req.params['key'] = api_key
      end

      handle_response(response)
    end

    private

    # Gets the API key from configuration or environment
    # @return [String] API key
    def api_key
      GeminiCache.configuration.api_key || ENV.fetch('GEMINI_API_KEY')
    end

    # Handles API responses
    # @param response [Faraday::Response] HTTP response
    # @return [Hash] parsed response body
    # @raise [ApiError] if response status is not 200
    def handle_response(response)
      return JSON.parse(response.body) if response.status == 200
      
      error_message = JSON.parse(response.body)['error'] rescue response.body
      raise ApiError, "API request failed (#{response.status}): #{error_message}"
    rescue Faraday::Error => e
      raise ApiError, "Network error: #{e.message}"
    end
  end
end 