module Tins
  module ProcCompose
    def compose(other)
      self.class.new do |*args|
        if other.respond_to?(:call)
          call(*other.call(*args))
        else
          call(*other.to_proc.call(*args))
        end
      end
    end

    alias * compose
  end
end
