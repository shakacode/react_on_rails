require "rails_helper"

shared_examples "railsContext" do |pathname, id_base|
  let(:http_accept_language) { "en-US,en;q=0.8" }

  subject { page }

  background do
    page.driver.headers = { 'ACCEPT-LANGUAGE' => http_accept_language }
    visit "/#{pathname}?ab=cd"
  end

  context pathname, :js do
    scenario "check rails context" do
      expect(current_path).to eq("/#{pathname}")
      host = Capybara.current_session.server.host
      port = Capybara.current_session.server.port
      host_port = "#{host}:#{port}"
      keysToVals = {
        href: "http://#{host_port}/#{pathname}?ab=cd",
        location: "/#{pathname}?ab=cd",
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

      keysToVals.each do |key, val|
        expect(page).to have_css("#{top_id} .js-#{key}", text: val)
      end
    end
  end
end

feature "rails_context" do
  context "client rendering" do
    context "shared store" do
      include_examples("railsContext",
                       "client_side_hello_world_shared_store",
                       "ReduxSharedStoreApp")
    end
  end

  context "server rendering" do
    context "shared store" do
      include_examples("railsContext",
                       "server_side_hello_world_shared_store",
                       "ReduxSharedStoreApp")
    end

    context "generator function for component" do
      include_examples("railsContext",
                       "server_side_redux_app",
                       "ReduxApp")
    end
  end
end

