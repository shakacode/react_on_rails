# frozen_string_literal: true

shared_examples "rsc_hello_server_controller" do
  it "creates HelloServer controller with react_on_rails_default layout" do
    assert_file "app/controllers/hello_server_controller.rb" do |content|
      expect(content).to include("class HelloServerController")
      expect(content).to include('layout "react_on_rails_default"')
      expect(content).to include("ReactOnRailsPro::Stream")
    end
  end

  it "creates HelloServer view with stream_react_component" do
    assert_file "app/views/hello_server/index.html.erb" do |content|
      expect(content).to include("HelloServer")
      expect(content).to include("stream_react_component")
    end
  end
end
