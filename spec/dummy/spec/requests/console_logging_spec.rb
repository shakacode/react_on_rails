require "rails_helper"

describe "Server Error Logging" do
  it "has server log messages in the script generated" do
    get root_path
    html_nodes = Nokogiri::HTML(response.body)

    expected = <<-JS
console.log.apply(console, ["[SERVER] RENDERED ReduxSharedStoreApp to dom node with id: ReduxSharedStoreApp-react-component-0 with railsContext:\",\"{\\\"inMailer\\\":false,\\\"i18nLocale\\\":\\\"en\\\",\\\"i18nDefaultLocale\\\":\\\"en\\\",\\\"href\\\":\\\"http://www.example.com/\\\",\\\"location\\\":\\\"/\\\",\\\"scheme\\\":\\\"http\\\",\\\"host\\\":\\\"www.example.com\\\",\\\"port\\\":null,\\\"pathname\\\":\\\"/\\\",\\\"search\\\":null,\\\"httpAcceptLanguage\\\":null,\\\"somethingUseful\\\":\\\"REALLY USEFUL\\\",\\\"serverSide\\\":true}\"]);
console.log.apply(console, ["[SERVER] This is a script:\\\"</div>\\\"(/script> <script>alert('WTF1')(/script>"]);
console.log.apply(console, ["[SERVER] Script2:\\\"</div>\\\"(/script xx> <script>alert('WTF2')(/script xx>"]);
console.log.apply(console, ["[SERVER] Script3:\\\"</div>\\\"(/script xx> <script>alert('WTF3')(/script xx>"]);
console.log.apply(console, ["[SERVER] Script4\\\"</div>\\\"(/script <script>alert('WTF4')(/script>"]);
console.log.apply(console, ["[SERVER] Script5:\\\"</div>\\\"(/script> <script>alert('WTF5')(/script>"]);
console.log.apply(console, ["[SERVER] railsContext.serverSide is ","true"]);
    JS

    expected_lines = expected.split("\n")

    script_node = html_nodes.css("script#consoleReplayLog")
    script_lines = script_node.text.split("\n")

    # First item is a blank line since expected script starts form "\n":
    script_lines.shift

    # Create external iterators for expected and found console replay script lines:
    expected_lines_iterator = expected_lines.to_enum
    script_lines_iterator = script_lines.to_enum

    loop do
      # rubocop:disable Lint/Void
      # Use built-in StopIteration handler of "loop" operator:
      StopIteration
      # rubocop:enable Lint/Void

      expected_line = expected_lines_iterator.next
      script_line = script_lines_iterator.next

      expect(script_line).to eq(expected_line)
    end
  end
end
