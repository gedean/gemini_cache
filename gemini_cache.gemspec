Gem::Specification.new do |s|
  s.name          = 'gemini_cache'
  s.version       = '0.0.7'
  s.date          = '2024-11-23'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'Ruby Gemini Context Caching'
  s.description   = "Ruby's Gemini Context Caching wrapper"
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'lib/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/gemini_cache'
  s.license       = 'MIT'
  s.add_dependency 'faraday', '~> 2'
  # s.post_install_message = %q{Please check readme file for use instructions.}
end
