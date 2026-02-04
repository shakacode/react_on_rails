# frozen_string_literal: true

require "rainbow"

module ReactOnRails
  # SmartError provides enhanced error messages with actionable suggestions
  # rubocop:disable Metrics/ClassLength
  class SmartError < Error
    attr_reader :component_name, :error_type, :props, :js_code, :additional_context

    def initialize(error_type:, component_name: nil, props: nil, js_code: nil, **additional_context)
      @error_type = error_type
      @component_name = component_name
      @props = props
      @js_code = js_code
      @additional_context = additional_context

      message = build_error_message
      super(message)
    end

    def solution
      case error_type
      when :component_not_registered
        component_not_registered_solution
      when :missing_auto_loaded_bundle
        missing_auto_loaded_bundle_solution
      when :missing_auto_loaded_store_bundle
        missing_auto_loaded_store_bundle_solution
      when :hydration_mismatch
        hydration_mismatch_solution
      when :server_rendering_error
        server_rendering_error_solution
      when :redux_store_not_found
        redux_store_not_found_solution
      when :configuration_error
        configuration_error_solution
      else
        default_solution
      end
    end

    private

    def build_error_message
      header = Rainbow("❌ React on Rails Error: #{error_type_title}").red.bright

      message = <<~MSG
        #{header}

        #{error_description}

        #{Rainbow('💡 Suggested Solution:').yellow.bright}
        #{solution}

        #{additional_info}
        #{troubleshooting_section}
      MSG

      message.strip
    end

    def error_type_title
      case error_type
      when :component_not_registered
        "Component '#{component_name}' Not Registered"
      when :missing_auto_loaded_bundle
        "Auto-loaded Bundle Missing"
      when :missing_auto_loaded_store_bundle
        "Auto-loaded Store Bundle Missing"
      when :hydration_mismatch
        "Hydration Mismatch"
      when :server_rendering_error
        "Server Rendering Failed"
      when :redux_store_not_found
        "Redux Store Not Found"
      when :configuration_error
        "Configuration Error"
      else
        "Unknown Error"
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def error_description
      case error_type
      when :component_not_registered
        <<~DESC
          Component '#{component_name}' was not found in the component registry.

          React on Rails offers two approaches:
          • Auto-bundling (recommended): Components load automatically, no registration needed
          • Manual registration: Traditional approach requiring explicit registration
        DESC
      when :missing_auto_loaded_bundle
        <<~DESC
          Component '#{component_name}' is configured for auto-loading but its bundle is missing.
          Expected location: #{additional_context[:expected_path]}
        DESC
      when :missing_auto_loaded_store_bundle
        <<~DESC
          Redux store '#{component_name}' is configured for auto-loading but its bundle is missing.
          Expected location: #{additional_context[:expected_path]}
        DESC
      when :hydration_mismatch
        <<~DESC
          The server-rendered HTML doesn't match what React rendered on the client.
          Component: #{component_name}
        DESC
      when :server_rendering_error
        <<~DESC
          An error occurred while server-side rendering component '#{component_name}'.
          #{additional_context[:error_message]}
        DESC
      when :redux_store_not_found
        <<~DESC
          Redux store '#{additional_context[:store_name]}' was not found.
          Available stores: #{additional_context[:available_stores]&.join(', ') || 'none'}
        DESC
      when :configuration_error
        <<~DESC
          Invalid configuration detected.
          #{additional_context[:details]}
        DESC
      else
        "An unexpected error occurred."
      end
    end

    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/AbcSize
    def component_not_registered_solution
      suggestions = []

      # Check for similar component names
      if component_name && !component_name.empty?
        similar = find_similar_components(component_name)
        suggestions << "Did you mean one of these? #{similar.map { |s| Rainbow(s).green }.join(', ')}" if similar.any?
      end

      suggestions << <<~SOLUTION
        #{Rainbow('🚀 Recommended: Use Auto-Bundling (No Registration Required!)').green.bright}

        1. Enable auto-bundling in your view:
           #{Rainbow("<%= react_component(\"#{component_name}\", props: {}, auto_load_bundle: true) %>").cyan}

        2. Place your component in the components directory:
           #{Rainbow("app/javascript/#{ReactOnRails.configuration.components_subdirectory || 'components'}/#{component_name}/#{component_name}.jsx").cyan}
        #{'   '}
           Component structure:
           #{Rainbow("#{ReactOnRails.configuration.components_subdirectory || 'components'}/").cyan}
           #{Rainbow("└── #{component_name}/").cyan}
           #{Rainbow("    └── #{component_name}.jsx").cyan} (must export default)

        3. Generate the bundle:
           #{Rainbow('bundle exec rake react_on_rails:generate_packs').cyan}

        #{Rainbow("✨ That's it! No manual registration needed.").yellow}

        ─────────────────────────────────────────────

        #{Rainbow('Alternative: Manual Registration').gray}

        If you prefer manual registration:
        1. Register in your entry file:
           #{Rainbow("ReactOnRails.register({ #{component_name}: #{component_name} });").cyan}

        2. Import the component:
           #{Rainbow("import #{component_name} from './components/#{component_name}';").cyan}
      SOLUTION

      suggestions.join("\n")
    end

    # rubocop:enable Metrics/AbcSize
    def missing_auto_loaded_bundle_solution
      <<~SOLUTION
        1. Run the pack generation task:
           #{Rainbow('bundle exec rake react_on_rails:generate_packs').cyan}

        2. Ensure your component is in the correct directory:
           #{Rainbow("app/javascript/#{ReactOnRails.configuration.components_subdirectory || 'components'}/#{component_name}/").cyan}

        3. Check that the component file follows naming conventions:
           - Component file: #{Rainbow("#{component_name}.jsx").cyan} or #{Rainbow("#{component_name}.tsx").cyan}
           - Must export default

        4. Verify webpack/shakapacker is configured for nested entries:
           #{Rainbow("config.nested_entries_dir = 'components'").cyan}
      SOLUTION
    end

    def missing_auto_loaded_store_bundle_solution
      <<~SOLUTION
        1. Run the pack generation task:
           #{Rainbow('bundle exec rake react_on_rails:generate_packs').cyan}

        2. Ensure your store is in the correct directory:
           #{Rainbow("app/javascript/#{ReactOnRails.configuration.stores_subdirectory || 'ror_stores'}/#{component_name}.js").cyan}

        3. Check that the store file follows naming conventions:
           - Store file: #{Rainbow("#{component_name}.js").cyan} or #{Rainbow("#{component_name}.ts").cyan}
           - Must export default a store generator function

        4. Verify stores_subdirectory is configured:
           #{Rainbow("config.stores_subdirectory = 'ror_stores'").cyan}
      SOLUTION
    end

    def hydration_mismatch_solution
      <<~SOLUTION
        Common causes and solutions:

        1. **Random IDs or timestamps**: Use consistent values between server and client
           #{Rainbow('// Bad: Math.random() or Date.now()').red}
           #{Rainbow('// Good: Use props or deterministic values').green}

        2. **Browser-only APIs**: Check for client-side before using:
           #{Rainbow("if (typeof window !== 'undefined') { ... }").cyan}

        3. **Different data**: Ensure props are identical on server and client
           - Check your redux store initialization
           - Verify railsContext is consistent

        4. **Conditional rendering**: Avoid using user agent or viewport checks

        Debug tips:
        - Set #{Rainbow('prerender: false').cyan} temporarily to isolate the issue
        - Check browser console for hydration warnings
        - Compare server HTML with client render
      SOLUTION
    end

    def server_rendering_error_solution
      <<~SOLUTION
        1. Check your JavaScript console output:
           #{Rainbow("tail -f log/development.log | grep 'React on Rails'").cyan}

        2. Common issues:
           - Missing Node.js dependencies: #{Rainbow('cd client && npm install').cyan}
           - Syntax errors in component code
           - Using browser-only APIs without checks

        3. Debug server rendering:
           - Set #{Rainbow('config.trace = true').cyan} in your configuration
           - Set #{Rainbow('config.development_mode = true').cyan} for better errors
           - Check #{Rainbow('config.server_bundle_js_file').cyan} points to correct file

        4. Verify your server bundle:
           #{Rainbow('bin/shakapacker').cyan} or #{Rainbow('bin/webpack').cyan}
      SOLUTION
    end

    def redux_store_not_found_solution
      <<~SOLUTION
        1. Register your Redux store:
           #{Rainbow("ReactOnRails.registerStore({ #{additional_context[:store_name]}: #{additional_context[:store_name]} });").cyan}

        2. Ensure the store is imported:
           #{Rainbow("import #{additional_context[:store_name]} from './store/#{additional_context[:store_name]}';").cyan}

        3. Initialize the store before rendering components that depend on it:
           #{Rainbow("<%= redux_store('#{additional_context[:store_name]}', props: {}) %>").cyan}

        4. Check store dependencies in your component:
           #{Rainbow("store_dependencies: ['#{additional_context[:store_name]}']").cyan}
      SOLUTION
    end

    def configuration_error_solution
      <<~SOLUTION
        Review your React on Rails configuration:

        1. Check #{Rainbow('config/initializers/react_on_rails.rb').cyan}

        2. Common configuration issues:
           - Invalid bundle paths
           - Missing Node modules location
           - Incorrect component subdirectory

        3. Run configuration doctor:
           #{Rainbow('rake react_on_rails:doctor').cyan}
      SOLUTION
    end

    def default_solution
      <<~SOLUTION
        1. Check the browser console for JavaScript errors
        2. Review your server logs: #{Rainbow('tail -f log/development.log').cyan}
        3. Run diagnostics: #{Rainbow('rake react_on_rails:doctor').cyan}
        4. Set #{Rainbow('FULL_TEXT_ERRORS=true').cyan} for complete error output
      SOLUTION
    end

    # rubocop:disable Metrics/AbcSize
    def additional_info
      info = []

      info << "#{Rainbow('Component:').blue} #{component_name}" if component_name

      if additional_context[:available_components]&.any?
        info << "#{Rainbow('Registered components:').blue} #{additional_context[:available_components].join(', ')}"
      end

      info << "#{Rainbow('Rails Environment:').blue} development (detailed errors enabled)" if Rails.env.development?

      info << "#{Rainbow('Auto-load bundles:').blue} enabled" if ReactOnRails.configuration.auto_load_bundle

      return "" if info.empty?

      "\n#{Rainbow('📋 Context:').blue.bright}\n#{info.join("\n")}"
    end

    # rubocop:enable Metrics/AbcSize
    def troubleshooting_section
      "\n#{Rainbow('🔧 Need More Help?').magenta.bright}\n#{Utils.default_troubleshooting_section}"
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def find_similar_components(name)
      return [] unless additional_context[:available_components]

      available = additional_context[:available_components]
      return [] if available.empty?

      available = available.uniq

      # Simple similarity check - could be enhanced with Levenshtein distance
      similar = available.select do |comp|
        comp.downcase.include?(name.downcase) || name.downcase.include?(comp.downcase)
      end

      # Also check for common naming patterns
      if similar.empty?
        # Check if user forgot to capitalize
        capitalized = name.capitalize
        similar = available.select { |comp| comp == capitalized }

        # Check for common suffixes
        if similar.empty? && !name.end_with?("Component")
          with_suffix = "#{name}Component"
          similar = available.select { |comp| comp == with_suffix }
        end
      end

      similar.take(3) # Limit suggestions
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
  # rubocop:enable Metrics/ClassLength
end
