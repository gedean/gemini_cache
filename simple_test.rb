require 'gemini_cache'
require 'pry'
require 'awesome_print'

url = 'https://noticias.uol.com.br/politica/ultimas-noticias/2024/11/25/relator-da-orcamento-de-2025-cai-na-malha-fina-da-cgu-sobre-emendas.htm'
GeminiCache.create_from_webpage url:, display_name: 'teste'

ap GeminiCache.list

binding.pry