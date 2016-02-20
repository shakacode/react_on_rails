require 'tilt/template'
require 'babel/transpiler'

module Tilt
  class BabelTemplate < Template
    def prepare
      options[:filename] ||= file
    end

    def evaluate(scope, locals, &block)
      @output ||= Babel::Transpiler.transform(data)["code"]
    end
  end
end

