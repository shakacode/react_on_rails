require "rails_helper"

describe "Server Rendering", :server_rendering do
  it "generates server rendered HTML if server renderering enabled" do
    get server_side_hello_world_with_options_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#my-hello-world-id").children.size).to eq(1)
    expect(html_nodes.css("div#my-hello-world-id h3").text)
      .to eq("Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("div#my-hello-world-id p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates server rendered HTML if server renderering enabled for shared redux" do
    get server_side_hello_world_shared_store_path
    html_nodes = Nokogiri::HTML(response.body)
    top_id = "#ReduxSharedStoreApp-react-component-0"
    expect(html_nodes.css(top_id).children.size).to eq(1)
    expect(html_nodes.css("#{top_id} h3").text)
      .to eq("Redux Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("#{top_id} p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates no server rendered HTML if server renderering not enabled" do
    get client_side_hello_world_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#HelloWorld-react-component-0").children.size).to eq(0)
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

  describe "server render mailer" do
    it "sends email okay" do
      mail = DummyMailer.hello_email
      expect(mail.subject).to match "mail"
      expect(mail.body).to match "Mr. Mailing Server Side Rendering"
      expect(mail.body).to match "\"inMailer\":true"
    end

    it "sets inMailer properly" do
      get client_side_hello_world_path
      html_nodes = Nokogiri::HTML(response.body)
      expect(html_nodes.at_css("script#js-react-on-rails-context").content)
        .to match("\"inMailer\":false")
    end
  end

  describe "server rendering railsContext" do
    let(:http_accept_language) { "en-US,en;q=0.8" }

    def check_match(pathname, id_base)
      html_nodes = Nokogiri::HTML(response.body)
      top_id = "##{id_base}-react-component-0"
      keys_to_vals = {
        href: "http://www.example.com/#{pathname}?ab=cd",
        location: "/#{pathname}?ab=cd",
        scheme: "http",
        host: "www.example.com",
        pathname: "/#{pathname}",
        search: "ab=cd",
        i18nLocale: "en",
        i18nDefaultLocale: "en",
        httpAcceptLanguage: http_accept_language,
        somethingUseful: "REALLY USEFUL"
      }
      keys_to_vals.each do |key, val|
        expect(html_nodes.css("#{top_id} .js-#{key}").text)
          .to eq(val)
      end
    end

    def do_request(path)
      get(path,
          { ab: :cd },
          "HTTP_ACCEPT_LANGUAGE" => http_accept_language)
    end

    context "shared redux store" do
      it "matches expected values" do
        do_request(server_side_hello_world_shared_store_path)
        check_match("server_side_hello_world_shared_store", "ReduxSharedStoreApp")
      end
    end

    context "generator function" do
      it "matches expected values" do
        do_request(server_side_redux_app_path)
        check_match("server_side_redux_app", "ReduxApp")
      end
    end
  end
end
