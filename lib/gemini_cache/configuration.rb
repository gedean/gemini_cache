module GeminiCache
  class Configuration
    attr_accessor :api_key, :api_base_url, :default_model, :default_ttl, :default_timeout

    def initialize
      @api_base_url = 'https://generativelanguage.googleapis.com'
      @default_model = 'gemini-flash-lite-latest'
      @default_ttl = 300
      @default_timeout = 300
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
