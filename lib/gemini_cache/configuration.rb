module GeminiCache
  # Configuration class for GeminiCache settings
  # @attr [String] api_key The API key for Gemini API
  # @attr [String] api_base_url The base URL for the Gemini API
  # @attr [String] default_model The default model to use
  # @attr [Integer] default_ttl The default time-to-live in seconds
  class Configuration
    attr_accessor :api_key, :api_base_url, :default_model, :default_ttl

    # Initializes a new Configuration with default values
    def initialize
      @api_base_url = 'https://generativelanguage.googleapis.com'
      @default_model = 'gemini-1.5-flash-8b'
      @default_ttl = 300
    end
  end

  class << self
    # @return [Configuration] current configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Configures GeminiCache
    # @yield [Configuration] configuration object
    # @example
    #   GeminiCache.configure do |config|
    #     config.api_key = 'your-api-key'
    #     config.default_ttl = 600
    #   end
    def configure
      yield(configuration)
    end
  end
end 