require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def create_redux_directories
        dirs = %w(actions constants reducers store)
        dirs.each { |name| empty_directory("client/app/bundles/MainPage/#{name}") }
      end

      def copy_base_redux_files
        base_path = "redux/base/"
        %w(client/app/bundles/MainPage/components/MainPage.jsx
           client/app/bundles/MainPage/actions/mainPageActionCreators.jsx
           client/app/bundles/MainPage/containers/MainPageContainer.jsx
           client/app/bundles/MainPage/constants/mainPageConstants.jsx
           client/app/bundles/MainPage/reducers/mainPageReducer.jsx
           client/app/bundles/MainPage/store/mainPageStore.jsx
           client/app/bundles/MainPage/startup/MainPageApp.jsx).each do |file|
             copy_file(base_path + file, file)
           end
      end

      def create_appropriate_templates
        base_path = "base/base/"
        location = "client/app/bundles/MainPage/"
        source = base_path + location
        config = {
          component_name: "MainPageApp",
          app_relative_path: "./MainPageApp"
        }
        template("#{source}/startup/registration.jsx.tt", "#{location}/startup/registration.jsx", config)
        template("#{base_path}app/views/main_page/index.html.erb.tt", "app/views/main_page/index.html.erb", config)
      end
    end
  end
end
