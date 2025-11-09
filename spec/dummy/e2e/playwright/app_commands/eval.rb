# frozen_string_literal: true

raise "eval command is only available in test environment" unless Rails.env.test?

Kernel.eval(command_options) unless command_options.nil?
