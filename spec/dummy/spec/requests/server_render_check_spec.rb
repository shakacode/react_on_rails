require "rails_helper"

describe "Server Rendering", :server_rendering do
  it "generates server rendered HTML if server rendering enabled" do
    get server_side_hello_world_with_options_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#my-hello-world-id").children.size).to eq(1)
    expect(html_nodes.css("div#my-hello-world-id h3").text)
      .to eq("Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("div#my-hello-world-id p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates server rendered HTML if server rendering enabled for shared redux" do
    get server_side_hello_world_shared_store_path
    html_nodes = Nokogiri::HTML(response.body)
    top_id = "#ReduxSharedStoreApp-react-component-0"
    expect(html_nodes.css(top_id).children.size).to eq(1)
    expect(html_nodes.css("#{top_id} h3").text)
      .to eq("Redux Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("#{top_id} p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates no server rendered HTML if server rendering not enabled" do
    get client_side_hello_world_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#HelloWorld-react-component-0").children.size).to eq(0)
  end

  describe "when using multiple bundles" do
    it "generates server rendered HTML using the specified bundle" do
      get server_side_hello_world_with_server_bundle_via_options_path
      html_nodes = Nokogiri::HTML(response.body)
      expect(html_nodes.css("div#my-hello-world-id").children.size).to eq(1)
      expect(html_nodes.css("div#my-hello-world-id h3").text).to eq("Hi, Mr. Server Side Rendering!")
    end
  end

  describe "reloading the server bundle" do
    let(:server_bundle) { File.expand_path("../../../app/assets/webpack/server-bundle.js", __FILE__) }
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
