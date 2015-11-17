require "rails_helper"

describe "Server Error Logging" do
  it "has server log messages in the script generated" do
    get server_side_log_throw_path
    html_nodes = Nokogiri::HTML(response.body)

    expected = <<-JS
console.log.apply(console, ["[SERVER] RENDERED HelloWorldWithLogAndThrow to dom node \
with id: HelloWorldWithLogAndThrow-react-component-0"]);
console.log.apply(console, ["[SERVER] console.log in HelloWorld"]);
console.warn.apply(console, ["[SERVER] console.warn in HelloWorld"]);
console.error.apply(console, ["[SERVER] console.error in HelloWorld"]);
console.error.apply(console, ["[SERVER] Exception in rendering!"]);
console.error.apply(console, ["[SERVER] message: throw in HelloWorldContainer"]);
console.error.apply(console, ["[SERVER] stack: Error: throw in HelloWorldContainer\n    at HelloWorldWithLogAndThrow
    JS

    expected_lines = expected.split("\n")

    script_node = html_nodes.css("script")[1]

    expected_lines.each do |line|
      expect(script_node.inner_text).to include(line)
    end
  end
end
