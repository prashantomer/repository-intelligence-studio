module Codebase
  class EntityExtractorRegistry
    def self.extractors_for(code_file)
      case code_file.language
      when "ruby"
        [RubyEntityExtractorService]
      when "javascript", "typescript"
        [JsTsEntityExtractorService]
      else
        []
      end
    end
  end
end
