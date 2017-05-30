require "rails_helper"

describe "Server Error Logging" do
  it "has server log messages in the script generated" do
    get server_side_log_throw_path
    html_nodes = Nokogiri::HTML(response.body)

    expected = <<-JS
console.log.apply(console, ["[SERVER] RENDERED MainPageWithLogAndThrow to dom node \
with id: MainPageWithLogAndThrow-react-component-0 with railsContext:"
console.log.apply(console, ["[SERVER] console.log in MainPage"]);
console.warn.apply(console, ["[SERVER] console.warn in MainPage"]);
console.error.apply(console, ["[SERVER] console.error in MainPage"]);
console.error.apply(console, ["[SERVER] Exception in rendering!"]);
console.error.apply(console, ["[SERVER] message: throw in MainPageContainer"]);
console.error.apply(console, ["[SERVER] stack: Error: throw in MainPageContainer\n    at MainPageWithLogAndThrow
    JS

    expected_lines = expected.split("\n")

    script_node = html_nodes.css("script#consoleReplayLog")

    expected_lines.each do |line|
      expect(script_node.text).to include(line)
    end
  end
end
