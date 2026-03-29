# frozen_string_literal: true

module ReactOnRails
  module Generators
    module DemoPageConfig # rubocop:disable Metrics/ModuleLength
      def build_hello_world_view_config(component_name:, source_path:, landing_page:, redux:, rsc_demo:)
        {
          component_name: component_name,
          title: redux ? "Redux SSR Demo" : "React SSR Demo",
          intro: hello_world_intro(redux: redux),
          highlights: hello_world_highlights(redux: redux),
          file_hints: hello_world_file_hints(source_path: source_path, redux: redux),
          quick_links: hello_world_quick_links(landing_page: landing_page, rsc_demo: rsc_demo),
          learning_links: hello_world_learning_links
        }
      end

      def build_hello_server_view_config(landing_page:, redux_demo:)
        {
          title: "React Server Components Demo",
          intro: "This route shows the Pro React Server Components flow: Rails streams an async server " \
                 "component response while only client islands ship JavaScript to the browser.",
          highlights: hello_server_highlights,
          file_hints: hello_server_file_hints,
          quick_links: hello_server_quick_links(landing_page: landing_page, redux_demo: redux_demo),
          learning_links: hello_server_learning_links
        }
      end

      private

      def new_app_landing_page_available?
        return false unless options[:new_app]

        routes_path = File.join(destination_root, "config/routes.rb")
        return false unless File.file?(routes_path)

        File.foreach(routes_path).any? do |line|
          !line.match?(/^\s*#/) && line.match?(/^\s*root\b/)
        end
      end

      def hello_world_intro(redux:)
        if redux
          "This route shows React on Rails with a Redux-backed component tree: Rails renders the initial HTML " \
            "on the server, then the client hydrates the app with the same store shape."
        else
          "This route shows the baseline React on Rails flow: Rails passes props into a server-rendered React " \
            "component, then the browser hydrates it for client-side interactivity."
        end
      end

      def hello_world_highlights(redux:)
        return redux_hello_world_highlights if redux

        [
          {
            title: "Controller props",
            description: "The Rails controller sets @hello_world_props before rendering this view."
          },
          {
            title: "Server render + hydrate",
            description: "react_component renders HTML on the server, then React attaches on the client."
          },
          {
            title: "Fast local iteration",
            description: "Edit the HelloWorld component while bin/dev is running to watch the demo update."
          }
        ]
      end

      def redux_hello_world_highlights
        [
          {
            title: "Redux store bootstrapping",
            description: "The demo store is created before render so the server and client see the same state."
          },
          {
            title: "Server render + hydrate",
            description: "The page still uses SSR first, then React and Redux take over in the browser."
          },
          {
            title: "Easy comparison with RSC",
            description: "Use this route as the baseline before evaluating the Pro RSC demo."
          }
        ]
      end

      def hello_world_file_hints(source_path:, redux:)
        source_description = if redux
                               "Redux-connected React source for the generated example app."
                             else
                               "React source for the generated HelloWorld component."
                             end
        controller_description = if redux
                                   "Rails controller that sets the props for the Redux demo."
                                 else
                                   "Rails controller that sets the props for this page."
                                 end
        view_description = if redux
                             "Rails view that mounts the Redux demo."
                           else
                             "Rails view that calls react_component for the demo."
                           end
        [
          {
            path: source_path,
            description: source_description
          },
          {
            path: "app/controllers/hello_world_controller.rb",
            description: controller_description
          },
          {
            path: "app/views/hello_world/index.html.erb",
            description: view_description
          },
          {
            path: "bin/dev",
            description: "Runs Rails and the asset watcher together while you iterate."
          }
        ]
      end

      def hello_world_quick_links(landing_page:, rsc_demo:)
        links = []
        links << { label: "Return to the generated home page", url: "/", external: false } if landing_page
        links << { label: "Open the RSC demo", url: "/hello_server", external: false } if rsc_demo
        links << {
          label: "Read the SSR tutorial",
          url: "https://reactonrails.com/docs/getting-started/tutorial/",
          external: true
        }
        links
      end

      def hello_world_learning_links
        [
          {
            label: "SSR tutorial",
            url: "https://reactonrails.com/docs/getting-started/tutorial/"
          },
          {
            label: "Compare OSS and Pro",
            url: "https://reactonrails.com/docs/getting-started/oss-vs-pro/"
          },
          {
            label: "Pro quick start",
            url: "https://reactonrails.com/docs/getting-started/pro-quick-start/"
          },
          {
            label: "Marketplace RSC demo",
            url: "https://github.com/shakacode/react-server-components-marketplace-demo"
          }
        ]
      end

      def hello_server_highlights
        [
          {
            title: "Async on the server",
            description: "HelloServer can await data directly during render without pushing that fetch to the client."
          },
          {
            title: "Small client footprint",
            description: "Only the interactive LikeButton island needs browser JavaScript."
          },
          {
            title: "Streaming output",
            description: "stream_react_component streams HTML as the server component tree resolves."
          }
        ]
      end

      def hello_server_file_hints
        [
          {
            path: "app/javascript/src/HelloServer/",
            description: "Source for the generated server component example and client island."
          },
          {
            path: "app/controllers/hello_server_controller.rb",
            description: "Rails controller that sets props and streams the RSC view."
          },
          {
            path: "app/views/hello_server/index.html.erb",
            description: "Rails view that calls stream_react_component."
          },
          {
            path: "client/node-renderer.js",
            description: "Node renderer entrypoint used by the Pro SSR and RSC stack."
          }
        ]
      end

      def hello_server_quick_links(landing_page:, redux_demo:)
        links = []
        links << { label: "Return to the generated home page", url: "/", external: false } if landing_page
        links << { label: "Open the Redux SSR demo", url: "/hello_world", external: false } if redux_demo
        links << {
          label: "Read the RSC guide",
          url: "https://reactonrails.com/docs/pro/react-server-components/",
          external: true
        }
        links
      end

      def hello_server_learning_links
        [
          {
            label: "RSC guide",
            url: "https://reactonrails.com/docs/pro/react-server-components/"
          },
          {
            label: "RSC tutorial",
            url: "https://reactonrails.com/docs/pro/react-server-components/tutorial/"
          },
          {
            label: "Pro overview",
            url: "https://reactonrails.com/pro/"
          },
          {
            label: "Marketplace RSC demo",
            url: "https://github.com/shakacode/react-server-components-marketplace-demo"
          }
        ]
      end
    end
  end
end
