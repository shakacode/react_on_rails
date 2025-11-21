# frozen_string_literal: true

require "rails_helper"

describe "Console logging from server" do
  let!(:default_replay_console_setting) { ReactOnRails.configuration.replay_console }

  after { ReactOnRails.configuration.replay_console = default_replay_console_setting }

  context 'when replay_console option set to "true"' do
    before { ReactOnRails.configuration.replay_console = true }

    it "has server log messages in the script generated" do
      get server_side_hello_world_shared_store_path
      html_nodes = Nokogiri::HTML(response.body)
      expected = <<~JS
        console.log.apply(console, ["[SERVER] RENDERED ReduxSharedStoreApp to dom node with id: ReduxSharedStoreApp-react-component-0"]);
        console.log.apply(console, ["[SERVER] This is a script:\\"</div>\\"(/script> <script>alert('WTF1')(/script>"]);
        console.log.apply(console, ["[SERVER] Script2:\\"</div>\\"(/script xx> <script>alert('WTF2')(/script xx>"]);
        console.log.apply(console, ["[SERVER] Script3:\\"</div>\\"(/script xx> <script>alert('WTF3')(/script xx>"]);
        console.log.apply(console, ["[SERVER] Script4\\"</div>\\"(/script <script>alert('WTF4')(/script>"]);
        console.log.apply(console, ["[SERVER] Script5:\\"</div>\\"(/script> <script>alert('WTF5')(/script>"]);
        console.log.apply(console, ["[SERVER] railsContext.serverSide is ","true"]);
        console.log.apply(console, ["[SERVER] RENDERED ReduxSharedStoreApp to dom node with id: ReduxSharedStoreApp-react-component-1"]);
      JS

      expected_lines = expected.split("\n")

      # When multiple components with replay_console are rendered, each creates its own script tag
      # with id="consoleReplayLog". Nokogiri's .text concatenates them without separators, which
      # breaks parsing. Instead, we explicitly join them with newlines.
      script_nodes = html_nodes.css("script#consoleReplayLog")
      script_text = script_nodes.map(&:text).join("\n")
      script_lines = script_text.split("\n")

      # Remove leading blank line if present (old format had it, new format doesn't)
      script_lines.shift if script_lines.first && script_lines.first.empty?

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

  context 'when replay_console option set to "false"' do
    before { ReactOnRails.configuration.replay_console = false }

    it "has no script with server log messages" do
      get root_path
      html_nodes = Nokogiri::HTML(response.body)
      expect(html_nodes.css("script#consoleReplayLog")).to be_empty
    end
  end
end
