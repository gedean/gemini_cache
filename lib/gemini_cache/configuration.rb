module GeminiCache
  class Configuration
    attr_accessor :api_key, :api_base_url, :default_model, :default_ttl

    def initialize
      @api_base_url = 'https://generativelanguage.googleapis.com'
      @default_model = 'gemini-1.5-flash-8b'
      @default_ttl = 300
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
