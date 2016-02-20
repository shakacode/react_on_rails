module Tins
  module AskAndSend
    def ask_and_send(method_name, *args, &block)
      if respond_to?(method_name)
        __send__(method_name, *args, &block)
      end
    end

    def ask_and_send!(method_name, *args, &block)
      if respond_to?(method_name, true)
        __send__(method_name, *args, &block)
      end
    end

    def ask_and_send_or_self(method_name, *args, &block)
      if respond_to?(method_name)
        __send__(method_name, *args, &block)
      else
        self
      end
    end

    def ask_and_send_or_self!(method_name, *args, &block)
      if respond_to?(method_name, true)
        __send__(method_name, *args, &block)
      else
        self
      end
    end
  end
end
