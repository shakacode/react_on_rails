module Tins
  module Responding
    def responding?(*method_names)
      Class.new do
        define_method(:to_s) do
          "Responding to #{method_names * ', '}"
        end

        alias inspect to_s

        define_method(:===) do |object|
          method_names.all? do |method_name|
            object.respond_to?(method_name)
          end
        end
      end.new
    end
  end
end
