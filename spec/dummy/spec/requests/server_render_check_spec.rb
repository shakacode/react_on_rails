require "rails_helper"

describe "Server Rendering" do
  it "generates server rendered HTML if server renderering enabled" do
    get server_side_hello_world_with_options_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#my-hello-world-id").children.size).to eq(1)
    expect(html_nodes.css("div#my-hello-world-id h3").text)
      .to eq("Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("div#my-hello-world-id p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates no server rendered HTML if server renderering not enabled" do
    get client_side_hello_world_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#HelloWorld-react-component-0").children.size).to eq(0)
  end

  describe "reloading the server bundle" do
    let(:server_bundle) { File.expand_path("../../../app/assets/javascripts/generated/server.js", __FILE__) }
    let!(:original_bundle_text) { File.read(server_bundle) }
    before do
      ReactOnRails.configure { |config| config.development_mode = true }
    end
    after do
      File.open(server_bundle, "w") { |f| f.puts original_bundle_text }
      ReactOnRails.configure { |config| config.development_mode = false }
    end
    it "reloads the server bundle on a new request if was changed" do
      get server_side_hello_world_with_options_path
      html_nodes = Nokogiri::HTML(response.body)
      sentinel = "Say hello to:"
      expect(html_nodes.css("div#my-hello-world-id p").text).to eq(sentinel)
      original_mtime = File.mtime(server_bundle)
      replacement_text = "ZZZZZZZZZZZZZZZZZZZ"
      new_bundle_text = original_bundle_text.gsub(sentinel, replacement_text)
      File.open(server_bundle, "w") { |f| f.puts new_bundle_text }
      new_mtime = File.mtime(server_bundle)
      expect(new_mtime).not_to eq(original_mtime)
      get server_side_hello_world_with_options_path
      new_html_nodes = Nokogiri::HTML(response.body)
      expect(new_html_nodes.css("div#my-hello-world-id p").text).to eq(replacement_text)
    end
  end
end
