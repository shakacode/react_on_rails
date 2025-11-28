# frozen_string_literal: true

module ReactOnRailsPro
  # AsyncRendering enables concurrent rendering of multiple React components.
  # When enabled, async_react_component calls will execute their HTTP requests
  # in parallel instead of sequentially.
  #
  # @example Enable for all actions
  #   class ProductsController < ApplicationController
  #     include ReactOnRailsPro::AsyncRendering
  #     enable_async_react_rendering
  #   end
  #
  # @example Enable for specific actions only
  #   class ProductsController < ApplicationController
  #     include ReactOnRailsPro::AsyncRendering
  #     enable_async_react_rendering only: [:show, :index]
  #   end
  #
  # @example Enable for all except specific actions
  #   class ProductsController < ApplicationController
  #     include ReactOnRailsPro::AsyncRendering
  #     enable_async_react_rendering except: [:create, :update]
  #   end
  #
  module AsyncRendering
    extend ActiveSupport::Concern

    class_methods do
      # Enables async React component rendering for controller actions.
      # Accepts standard Rails filter options like :only and :except.
      #
      # @param options [Hash] Options passed to around_action (e.g., only:, except:)
      def enable_async_react_rendering(**options)
        around_action :wrap_in_async_react_context, **options
      end
    end

    private

    def wrap_in_async_react_context
      require "async"
      require "async/barrier"

      Sync do
        @react_on_rails_async_barrier = Async::Barrier.new
        yield
        check_for_unresolved_async_components
      ensure
        @react_on_rails_async_barrier&.stop
        @react_on_rails_async_barrier = nil
      end
    end

    def check_for_unresolved_async_components
      return if @react_on_rails_async_barrier.nil?

      pending_tasks = @react_on_rails_async_barrier.size
      return if pending_tasks.zero?

      Rails.logger.error(
        "[React on Rails Pro] #{pending_tasks} async component(s) were started but never resolved. " \
        "Make sure to call .value on all AsyncValue objects returned by async_react_component " \
        "or cached_async_react_component. Unresolved tasks will be stopped."
      )
    end
  end
end
