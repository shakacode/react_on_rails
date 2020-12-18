# frozen_string_literal: true

require "rails_helper"

shared_examples "railsContext" do |pathname, id_base|
  subject { page }

  let(:http_accept_language) { "en-US,en;q=0.8" }

  before do
    visit "/#{pathname}?ab=cd"
  end

  context "when visting /#{pathname}", :js, type: :system do
    scenario "check rails context" do
      expect(page).to have_current_path("/#{pathname}", ignore_query: true)
      host = Capybara.current_session.server.host
      port = Capybara.current_session.server.port
      host_port = "#{host}:#{port}"
      keys_to_vals = {
        railsEnv: Rails.env,
        rorVersion: ReactOnRails::VERSION,
        rorPro: ReactOnRails::Utils.react_on_rails_pro?,
        href: "http://#{host_port}/#{pathname}?ab=cd",
        location: "/#{pathname}?ab=cd",
        port: port,
        scheme: "http",
        host: host,
        pathname: "/#{pathname}",
        search: "ab=cd",
        i18nLocale: "en",
        i18nDefaultLocale: "en",
        httpAcceptLanguage: http_accept_language,
        somethingUseful: "REALLY USEFUL"
      }

      top_id = "##{id_base}-react-component-0"

      keys_to_vals.each do |key, val|
        # skip checking http_accept_language if selenium
        next if key == :httpAcceptLanguage && Capybara.javascript_driver.to_s.include?("selenium")

        expect(page).to have_css("#{top_id} .js-#{key}", text: val)
      end
    end
  end
end

describe "rails_context" do
  context "when client rendering" do
    context "with shared store" do
      include_examples("railsContext",
                       "client_side_hello_world_shared_store",
                       "ReduxSharedStoreApp")
    end
  end

  context "when server rendering" do
    context "with shared store" do
      include_examples("railsContext",
                       "server_side_hello_world_shared_store",
                       "ReduxSharedStoreApp")
    end

    context "with Render-Function for component" do
      include_examples("railsContext",
                       "server_side_redux_app",
                       "ReduxApp")
    end
  end
end
