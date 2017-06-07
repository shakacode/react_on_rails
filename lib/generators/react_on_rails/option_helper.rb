module OptionHelper
  extend ActiveSupport::Concern

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
