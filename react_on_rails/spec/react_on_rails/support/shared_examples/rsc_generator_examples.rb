# frozen_string_literal: true

shared_examples "rsc_hello_server_files" do
  it "creates HelloServer controller with hello_world layout" do
    assert_file "app/controllers/hello_server_controller.rb" do |content|
      expect(content).to include("class HelloServerController")
      expect(content).to include('layout "hello_world"')
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
