module Embeddings
  module VectorLiteral
    module_function

    def dump(values)
      "[#{values.map { |value| format("%.8f", value) }.join(",")}]"
    end
  end
end
