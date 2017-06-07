module OptionHelper
  def define_name_option
    # --name
    class_option :name,
                 type: :string,
                 default: "HelloWorld",
                 desc: "Name the example page NAME"
  end
end
