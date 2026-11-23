# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/server_render_http_response"

module ReactOnRails
  describe ServerRenderHttpResponse do
    # A minimal stand-in for ActionDispatch::Response.
    let(:response_class) do
      Struct.new(:status, :location, :committed) do
        def committed?
          committed
        end
      end
    end
    let(:rails_response) { response_class.new(200, nil, false) }

    def apply(http_response, current_path: "/current")
      described_class.apply(http_response, response: rails_response, current_path:, component_name: "App")
    end

    describe ".apply" do
      it "does nothing when there is no httpResponse" do
        expect(apply(nil)).to be(false)
        expect(rails_response.status).to eq(200)
        expect(rails_response.location).to be_nil
      end

      it "sets a 404 status and keeps the Location header empty" do
        expect(apply({ "status" => 404 })).to be(true)
        expect(rails_response.status).to eq(404)
        expect(rails_response.location).to be_nil
      end

      it "sets a 500 status" do
        expect(apply({ "status" => 500 })).to be(true)
        expect(rails_response.status).to eq(500)
      end

      it "sets the status and the Location header for a redirect to a path on this site" do
        expect(apply({ "status" => 307, "location" => "/login?next=%2Fdashboard" })).to be(true)
        expect(rails_response.status).to eq(307)
        expect(rails_response.location).to eq("/login?next=%2Fdashboard")
      end

      it "accepts every redirect status that Rails supports with a Location header" do
        [301, 302, 303, 307, 308].each do |status|
          fresh_response = response_class.new(200, nil, false)
          applied = described_class.apply({ "status" => status, "location" => "/next" },
                                          response: fresh_response, current_path: "/current", component_name: "App")

          expect(applied).to be(true)
          expect(fresh_response.status).to eq(status)
        end
      end

      it "does nothing when the response was already sent" do
        rails_response.committed = true

        expect(apply({ "status" => 404 })).to be(false)
        expect(rails_response.status).to eq(200)
      end

      it "does nothing when the controller already chose a status" do
        rails_response.status = 403

        expect(apply({ "status" => 404 })).to be(false)
        expect(rails_response.status).to eq(403)
      end

      it "does nothing when there is no response object" do
        applied = described_class.apply({ "status" => 404 }, response: nil, current_path: nil, component_name: "App")

        expect(applied).to be(false)
      end

      it "does nothing when the redirect points at the current URL" do
        expect(apply({ "status" => 307, "location" => "/current" }, current_path: "/current")).to be(false)
        expect(rails_response.status).to eq(200)
        expect(rails_response.location).to be_nil
      end

      it "does nothing when the redirect points at the current URL plus a fragment" do
        expect(apply({ "status" => 307, "location" => "/current#team" }, current_path: "/current")).to be(false)
        expect(rails_response.status).to eq(200)
        expect(rails_response.location).to be_nil
      end

      it "keeps the fragment of a redirect to another path" do
        expect(apply({ "status" => 302, "location" => "/login#form" }, current_path: "/current")).to be(true)
        expect(rails_response.location).to eq("/login#form")
      end

      it "ignores a redirect to another website or an unsafe location" do
        [
          "https://example.com/x",
          "//example.com/x",
          "/\\example.com/x",
          "login",
          "/a b",
          "/a\r\nSet-Cookie: x=1",
          "",
          42
        ].each do |location|
          expect(apply({ "status" => 307, "location" => location })).to be(false)
          expect(rails_response.status).to eq(200)
          expect(rails_response.location).to be_nil
        end
      end

      it "ignores a location with a status that is not a redirect status" do
        expect(apply({ "status" => 404, "location" => "/login" })).to be(false)
        expect(rails_response.status).to eq(200)
      end

      it "ignores a status-only value outside 400-599" do
        [200, 204, 307, 600].each do |status|
          expect(apply({ "status" => status })).to be(false)
          expect(rails_response.status).to eq(200)
        end
      end

      it "ignores a malformed value" do
        ["404", { "status" => "404" }, { "location" => "/login" }, [404]].each do |value|
          expect(apply(value)).to be(false)
          expect(rails_response.status).to eq(200)
        end
      end
    end

    describe ".normalize" do
      it "returns the status and location for a usable redirect" do
        expect(described_class.normalize({ "status" => 301, "location" => "/a" }, component_name: "App"))
          .to eq({ status: 301, location: "/a" })
      end

      it "returns the status for a usable error status" do
        expect(described_class.normalize({ "status" => 404 }, component_name: "App"))
          .to eq({ status: 404, location: nil })
      end
    end
  end
end
