# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/renderer_http_client"

RSpec.describe ReactOnRailsPro::RendererHttpClient do
  describe ReactOnRailsPro::RendererHttpClient::Response do
    it "does not treat an unknown status as an error" do
      response = described_class.new

      expect(response).not_to be_error
    end

    it "yields streamed chunks and raises an HTTPError after consuming an error response" do
      response = described_class.new(status: 410, body: ["Bundle ", "Required"])
      chunks = []

      expect do
        response.each { |chunk| chunks << chunk }
      end.to raise_error(ReactOnRailsPro::RendererHttpClient::HTTPError) { |error|
        expect(error.response).to be(response)
        expect(error.response.body).to eq("Bundle Required")
      }

      expect(chunks).to eq(["Bundle ", "Required"])
    end
  end

  describe ".build_multipart_body" do
    it "encodes scalar, array, and uploaded file fields" do
      Tempfile.create(["react-on-rails-pro", ".js"]) do |file|
        file.write("console.log('bundle');")
        file.rewind

        form = {
          "password" => "secret",
          "targetBundles" => %w[server rsc],
          "bundle_server" => {
            body: Pathname.new(file.path),
            content_type: "text/javascript",
            filename: "server.js"
          }
        }

        headers, body = described_class.build_multipart_body(form, boundary: "rorp-test-boundary")

        expect(headers).to include(["content-type", "multipart/form-data; boundary=rorp-test-boundary"])
        expect(headers).not_to include(["content-length", body.bytesize.to_s])
        expect(body).to include('name="password"')
        expect(body).to include("secret")
        expect(body).to include('name="targetBundles[]"')
        expect(body).to include("server")
        expect(body).to include("rsc")
        expect(body).to include('name="bundle_server"; filename="server.js"')
        expect(body).to include("Content-Type: text/javascript")
        expect(body).to include("console.log('bundle');")
      end
    end
  end

  describe ".build_form_body" do
    it "uses url-encoded form data when no uploaded files are present" do
      headers, body = described_class.build_form_body(
        {
          "password" => "secret",
          "targetBundles" => %w[server rsc],
          "renderingRequest" => "console.log('Hello, world!');"
        }
      )

      expect(headers).to eq([["content-type", "application/x-www-form-urlencoded"]])
      expect(body).to include("password=secret")
      expect(body).to include("targetBundles%5B%5D=server")
      expect(body).to include("targetBundles%5B%5D=rsc")
      expect(body).to include("renderingRequest=console.log")
    end

    it "uses multipart form data when uploaded files are present" do
      Tempfile.create(["react-on-rails-pro", ".js"]) do |file|
        form = {
          "password" => "secret",
          "bundle_server" => {
            body: Pathname.new(file.path),
            content_type: "text/javascript",
            filename: "server.js"
          }
        }

        headers, body = described_class.build_form_body(form)

        expect(headers).to contain_exactly(
          a_collection_containing_exactly("content-type", a_string_starting_with("multipart/form-data; boundary="))
        )
        expect(body).to include('name="bundle_server"; filename="server.js"')
      end
    end
  end

  describe ".get" do
    it "does not force HTTP/2 for arbitrary dev-server asset URLs" do
      response = described_class::Response.new(status: 200, body: ["asset"])
      client = instance_double(described_class, get: response)

      allow(described_class).to receive(:new).and_return(client)

      expect(described_class.get("http://localhost:3035/packs/server.js", connect_timeout: 1, read_timeout: 2))
        .to be(response)

      expect(described_class).to have_received(:new).with(
        origin: "http://localhost:3035",
        pool_size: 1,
        connect_timeout: 1,
        read_timeout: 2,
        force_http2: false
      )
    end
  end
end
