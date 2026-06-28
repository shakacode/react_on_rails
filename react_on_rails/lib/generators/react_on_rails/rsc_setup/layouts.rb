# frozen_string_literal: true

module ReactOnRails
  module Generators
    module RscSetup
      module Layouts
        private

        def resolve_hello_server_layout_name
          classification_by_layout = candidate_layout_names.to_h do |layout_name|
            [layout_name, classify_hello_server_layout(layout_name)]
          end

          reusable_layout_name = find_reusable_hello_server_layout_name(classification_by_layout)
          return reusable_layout_name if reusable_layout_name

          create_new_hello_server_layout(
            skipped_layout_paths: skipped_existing_layout_paths(classification_by_layout)
          )
        end

        def find_reusable_hello_server_layout_name(classification_by_layout)
          declared_layout_name = hello_world_controller_layout_name

          if reusable_layout_classification?(classification_by_layout[declared_layout_name])
            announce_reused_hello_server_layout(declared_layout_name, classification_by_layout[declared_layout_name])
            return declared_layout_name
          end

          preferred_layout_name = first_layout_name_with_classification(
            classification_by_layout,
            :canonical,
            excluding: declared_layout_name
          )
          return preferred_layout_name if preferred_layout_name

          first_layout_name_with_reusable_classification(
            classification_by_layout,
            excluding: declared_layout_name
          )
        end

        def first_layout_name_with_classification(classification_by_layout, expected_classification, excluding: nil)
          classification_by_layout.each do |layout_name, classification|
            next if layout_name == excluding
            next unless classification == expected_classification

            announce_reused_hello_server_layout(layout_name, classification)
            return layout_name
          end

          nil
        end

        def first_layout_name_with_reusable_classification(classification_by_layout, excluding: nil)
          classification_by_layout.each do |layout_name, classification|
            next if layout_name == excluding
            next unless reusable_layout_classification?(classification)

            announce_reused_hello_server_layout(layout_name, classification)
            return layout_name
          end

          nil
        end

        def announce_reused_hello_server_layout(layout_name, classification)
          message = +"ℹ️  Reusing existing #{layout_name} layout for HelloServerController"
          message << " (new generated layouts use empty pack tags by default)" if classification == :reusable
          say message, :yellow
        end

        def candidate_layout_names
          [
            hello_world_controller_layout_name,
            DEFAULT_LAYOUT_NAME,
            LEGACY_LAYOUT_NAME,
            *existing_rsc_layout_names
          ].compact.uniq
        end

        def hello_world_controller_layout_name
          return @hello_world_controller_layout_name if defined?(@hello_world_controller_layout_name)

          controller_path = File.join(destination_root, "app/controllers/hello_world_controller.rb")
          @hello_world_controller_layout_name = if File.exist?(controller_path)
                                                  extract_declared_layout_name(File.read(controller_path))
                                                end
        end

        def existing_rsc_layout_names
          Dir.glob(File.join(destination_root, "app/views/layouts/react_on_rails_rsc*.html.erb"))
             .map { |path| File.basename(path, ".html.erb") }
             .select { |layout_name| generated_rsc_layout_name?(layout_name) }
        end

        def generated_rsc_layout_name?(layout_name)
          layout_name.match?(RSC_GENERATED_LAYOUT_NAME_PATTERN)
        end

        def classify_hello_server_layout(layout_name)
          layout_path = layout_destination_path(layout_name)
          full_path = File.join(destination_root, layout_path)
          return :missing unless File.exist?(full_path)

          layout_content = File.read(full_path)
          return :missing_pack_tags unless layout_has_required_pack_tags?(layout_content)

          return :canonical if layout_uses_canonical_pack_tags?(layout_content)

          :reusable
        end

        def skipped_existing_layout_paths(classification_by_layout)
          classification_by_layout.filter_map do |layout_name, classification|
            layout_path = layout_destination_path(layout_name)
            full_path = File.join(destination_root, layout_path)

            next unless File.exist?(full_path)
            next if reusable_layout_classification?(classification)

            layout_path
          end
        end

        def layout_has_required_pack_tags?(layout_content)
          pack_tag_present?(layout_content, "javascript_pack_tag") &&
            pack_tag_present?(layout_content, "stylesheet_pack_tag")
        end

        def layout_uses_canonical_pack_tags?(layout_content)
          pack_tag_without_names?(layout_content, "javascript_pack_tag") &&
            pack_tag_without_names?(layout_content, "stylesheet_pack_tag")
        end

        def reusable_layout_classification?(classification)
          %i[canonical reusable].include?(classification)
        end

        def pack_tag_present?(layout_content, helper_name)
          pack_tag_arguments(layout_content, helper_name).any?
        end

        def pack_tag_without_names?(layout_content, helper_name)
          arguments = pack_tag_arguments(layout_content, helper_name)
          arguments.any? && arguments.all? do |pack_tag_arguments|
            pack_tag_arguments_without_names?(pack_tag_arguments)
          end
        end

        def pack_tag_arguments(layout_content, helper_name)
          arguments_pattern = '\s*(?:\((?:(?!%>).)*?\)|(?:(?!%>).)*?)'
          pattern = /<%=\s*#{Regexp.escape(helper_name)}(?=\s|\(|%>)(?<arguments>#{arguments_pattern})?\s*%>/m

          arguments = []
          layout_content.scan(pattern) do
            arguments << Regexp.last_match[:arguments]
          end

          arguments
        end

        def pack_tag_arguments_without_names?(arguments)
          normalized_arguments = strip_wrapping_parentheses(arguments.to_s.strip)
          return true if normalized_arguments.empty?

          normalized_arguments.match?(/\A(?:\*\*[A-Za-z_]\w*|[a-z_]\w*\s*:.*)\z/m)
        end

        def strip_wrapping_parentheses(arguments)
          return arguments unless arguments.start_with?("(") && arguments.end_with?(")")

          arguments[1...-1].strip
        end

        def create_new_hello_server_layout(skipped_layout_paths: [])
          layout_name = next_available_hello_server_layout_name
          layout_path = layout_destination_path(layout_name)

          announce_skipped_layout_fallback(skipped_layout_paths, layout_path) if skipped_layout_paths.any?

          say "📝 Creating #{layout_path} for HelloServerController...", :yellow
          empty_directory("app/views/layouts")
          template_dir = use_tailwind? ? "base/tailwind" : "base/base"
          copy_file("templates/#{template_dir}/app/views/layouts/react_on_rails_default.html.erb", layout_path)
          say "✅ Created #{layout_path}", :green

          layout_name
        end

        def announce_skipped_layout_fallback(skipped_layout_paths, new_layout_path)
          skipped_paths = skipped_layout_paths.map { |path| "  - #{path}" }.join("\n")

          say <<~MSG, :yellow
            ℹ️  Found existing layout file(s) in your app that were not reused for HelloServerController:
            #{skipped_paths}

            Those file(s) do not include both `stylesheet_pack_tag` and `javascript_pack_tag`, so the generator
            will create #{new_layout_path} instead of overwriting them.
            #{fallback_layout_description}
          MSG
        end

        def fallback_layout_description
          if use_tailwind?
            "The new generated layout will include the layout-owned Tailwind pack block."
          else
            "New generated layouts use empty pack tags by default."
          end
        end

        def next_available_hello_server_layout_name
          default_layout_path = File.join(destination_root, layout_destination_path(DEFAULT_LAYOUT_NAME))
          return DEFAULT_LAYOUT_NAME unless File.exist?(default_layout_path)

          fallback_layout_path = File.join(destination_root, layout_destination_path(RSC_FALLBACK_LAYOUT_NAME))
          return RSC_FALLBACK_LAYOUT_NAME unless File.exist?(fallback_layout_path)

          (2..MAX_LAYOUT_NAME_ATTEMPTS).each do |suffix|
            layout_name = "#{RSC_FALLBACK_LAYOUT_NAME}_#{suffix}"
            return layout_name unless File.exist?(File.join(destination_root, layout_destination_path(layout_name)))
          end

          raise "Could not find an available RSC layout name after #{MAX_LAYOUT_NAME_ATTEMPTS} attempts."
        end
      end
    end
  end
end
