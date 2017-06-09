module OptionHelper
  extend ActiveSupport::Concern

  def example_page_name
    options.example_page_name.camelize
  end

  def example_page_js_filename
    options.example_page_name.camelize :lower
  end

  def example_page_title
    options.example_page_name.underscore.humanize.titleize
  end

  def example_page_path
    options.example_page_name.underscore
  end

  module ClassMethods
    def define_name_option
      # --example-page-name=NAME
      class_option :"example_page_name",
                   type: :string,
                   default: "HelloWorld",
                   desc: "Name the example page EXAMPLE-PAGE-NAME",
                   aliases: "-E"
    end
  end
end
