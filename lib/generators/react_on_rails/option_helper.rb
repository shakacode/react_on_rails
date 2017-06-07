module OptionHelper
  extend ActiveSupport::Concern

  def example_page_name
    options.example_page_name.capitalize
  end

  def example_page_path
    options.example_page_name.underscore
  end

  def dst_filename(src_filename)
    src_filename.gsub /hello_world/, example_page_path
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
