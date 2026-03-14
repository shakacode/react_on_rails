# frozen_string_literal: true

shared_examples "rsc_common_files" do
  it "copies common files" do
    %w[config/initializers/react_on_rails.rb
       Procfile.dev
       Procfile.dev-static-assets
       Procfile.dev-prod-assets
       app/views/layouts/react_on_rails_default.html.erb].each { |file| assert_file(file) }
  end

  it "creates Pro initializer with RSC configuration" do
    assert_file "config/initializers/react_on_rails_pro.rb" do |content|
      expect(content).to include("ReactOnRailsPro.configure")
      expect(content).to include("enable_rsc_support = true")
      expect(content).to include('rsc_bundle_js_file = "rsc-bundle.js"')
      expect(content).to include('rsc_payload_generation_url_path = "rsc_payload/"')
    end
  end
end

shared_examples "rsc_hello_server_files" do |layout_name = "react_on_rails_default"|
  it "creates HelloServer controller with #{layout_name} layout" do
    assert_file "app/controllers/hello_server_controller.rb" do |content|
      expect(content).to include("class HelloServerController")
      expect(content).to include(%(layout "#{layout_name}"))
      expect(content).to include("ReactOnRailsPro::Stream")
    end
  end

  it "creates HelloServer view with stream_react_component" do
    assert_file "app/views/hello_server/index.html.erb" do |content|
      expect(content).to include("HelloServer")
      expect(content).to include("stream_react_component")
      expect(content).not_to include("prerender: true")
    end
  end
end
