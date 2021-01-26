# frozen_string_literal: true

require "rails_helper"

shared_examples "railsContext" do |pathname, id_base, options|
  subject { page }

  let(:http_accept_language) { "en-US,en;q=0.8" }

  before do
    if options[:rorPro]
      doubled_spec = instance_double(Gem::Specification)
      allow(Gem::Specification).to receive(:find_all_by_name).with("react_on_rails_pro").and_return([doubled_spec])
      allow(Gem::Specification).to receive(:find_all_by_name).with("webpacker")
      allow(doubled_spec).to receive(:version).and_return("1.1.1")
    end
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

      keys_to_vals[:rorProVersion] = "1.1.1" if options[:rorPro]
      keys_to_vals[:rorPro] = options[:rorPro].to_s


      p "key_to_vals"
      p keys_to_vals

      top_id = "##{id_base}-react-component-0"

      p "specific elements"
      p find(:css, "#{top_id} .js-rorPro").text
      p find(:css, "#{top_id} .js-rorProVersion").text

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
      context "with mocked react_on_rails_pro gem", :focus do
        include_examples("railsContext",
                         "client_side_hello_world_shared_store",
                         "ReduxSharedStoreApp",
                         { rorPro: true })
      end

      context "without mocked react_on_rails_pro gem" do
        include_examples("railsContext",
                         "client_side_hello_world_shared_store",
                         "ReduxSharedStoreApp",
                         { rorPro: false })
      end
    end
  end

  context "when server rendering" do
    context "with shared store" do
      include_examples("railsContext",
                       "server_side_hello_world_shared_store",
                       "ReduxSharedStoreApp",
                       { rorPro: false })
    end

    context "with Render-Function for component" do
      include_examples("railsContext",
                       "server_side_redux_app",
                       "ReduxApp",
                       { rorPro: false })
    end
  end
end
