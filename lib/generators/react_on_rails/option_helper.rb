# frozen_string_literal: true

module OptionHelper
  extend ActiveSupport::Concern

  def example_page_name
    options.example_page_name.camelize
  end

  def example_page_lower_camelcase
    options.example_page_name.camelize :lower
  end

  def example_page_title
    options.example_page_name.underscore.humanize.titleize
  end

  def example_page_path
    options.example_page_name.underscore
  end

  def example_page_path_in_caps
    example_page_path.upcase
  end

  def convert_filename_to_use_example_page_name(file)
    file.gsub("hello_world", example_page_path)
        .gsub("HelloWorld", example_page_name)
        .gsub("helloWorld", example_page_lower_camelcase)
  end

  module ClassMethods
    def define_name_option
      # --example-page-name=NAME
      class_option :example_page_name,
                   type: :string,
                   default: "HelloWorld",
                   desc: "Name the example page EXAMPLE_PAGE_NAME",
                   aliases: "-E"
    end
  end
end
