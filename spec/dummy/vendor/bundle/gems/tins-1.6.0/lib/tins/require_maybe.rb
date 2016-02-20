module Tins
  module RequireMaybe
    def require_maybe(library)
      require library
    rescue LoadError => e
      block_given? and yield e
    end
  end
end
