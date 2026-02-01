# frozen_string_literal: true

require "jwt"

module ReactOnRailsPro
  # Validates React on Rails Pro licenses.
  # This class only determines license status - it does NOT log.
  # All logging is handled by Engine.log_license_status for environment-aware messaging.
  # rubocop:disable Metrics/ClassLength
  class LicenseValidator
    # Valid license plan types.
    # Must match VALID_PLANS in packages/react-on-rails-pro-node-renderer/src/shared/licenseValidator.ts
    # - paid: Standard commercial license
    # - startup: Complimentary for qualifying startups
    # - nonprofit: Complimentary for non-profits
    # - education: For educational institutions
    # - oss: For open source projects
    # - partner: Strategic partners
    VALID_PLANS = %w[paid startup nonprofit education oss partner].freeze

    # Plans that require attribution by default (complimentary licenses)
    #
    # Attribution defaults by plan:
    #   Plan       | Attribution Required?
    #   -----------|----------------------
    #   paid       | No
    #   partner    | No
    #   startup    | Yes
    #   oss        | Yes
    #   nonprofit  | No (default)
    #   education  | No (default)
    #
    # These defaults can be overridden by explicit "attribution" field in the license JWT.
    ATTRIBUTION_REQUIRED_PLANS = %w[startup oss].freeze

    # Mutex for thread-safe license status initialization.
    # Using a constant eliminates the race condition that would exist with @mutex ||= Mutex.new
    # See: https://bugs.ruby-lang.org/issues/20875
    LICENSE_MUTEX = Mutex.new

    class << self
      # Returns the current license status (never raises, never logs)
      # Thread-safe: uses Mutex to prevent race conditions during initialization
      # @return [Symbol] One of :valid, :expired, :invalid, :missing
      def license_status
        return @license_status if defined?(@license_status)

        LICENSE_MUTEX.synchronize do
          # Double-check pattern: another thread may have set it while we waited
          return @license_status if defined?(@license_status)

          @license_status = determine_license_status
        end
      end

      # Returns the license expiration time if available
      # @return [Time, nil] The expiration time or nil if not available
      def license_expiration
        return @license_expiration if defined?(@license_expiration)

        LICENSE_MUTEX.synchronize do
          return @license_expiration if defined?(@license_expiration)

          @license_expiration = determine_license_expiration
        end
      end

      # Returns the organization name from the license if available
      # @return [String, nil] The organization name or nil if not available
      def license_organization
        return @license_organization if defined?(@license_organization)

        LICENSE_MUTEX.synchronize do
          return @license_organization if defined?(@license_organization)

          @license_organization = determine_license_organization
        end
      end

      # Returns the license plan type if available
      # @return [String, nil] The plan type (e.g., "paid", "startup") or nil if not available
      def license_plan
        return @license_plan if defined?(@license_plan)

        LICENSE_MUTEX.synchronize do
          return @license_plan if defined?(@license_plan)

          @license_plan = determine_license_plan
        end
      end

      # Returns whether attribution is required for this license
      # Checks explicit attribution field first, then infers from plan type:
      # - paid, partner: No attribution required
      # - startup, oss: Attribution required
      # - nonprofit, education: Attribution optional (default: no)
      # @return [Boolean] True if attribution is required
      def attribution_required?
        return @attribution_required if defined?(@attribution_required)

        LICENSE_MUTEX.synchronize do
          return @attribution_required if defined?(@attribution_required)

          @attribution_required = determine_attribution_required
        end
      end

      # Returns license information for use in helpers and components
      # @return [Hash] License info including org, plan, status, and attribution_required
      def license_info
        {
          org: license_organization,
          plan: license_plan,
          status: license_status,
          attribution_required: attribution_required?,
          expiration: license_expiration
        }
      end

      # Resets all cached state (primarily for testing)
      def reset!
        LICENSE_MUTEX.synchronize do
          remove_instance_variable(:@license_status) if defined?(@license_status)
          remove_instance_variable(:@license_expiration) if defined?(@license_expiration)
          remove_instance_variable(:@license_organization) if defined?(@license_organization)
          remove_instance_variable(:@license_plan) if defined?(@license_plan)
          remove_instance_variable(:@attribution_required) if defined?(@attribution_required)
        end
      end

      private

      # Determines the license status by loading, decoding, and validating
      # @return [Symbol] The license status
      def determine_license_status
        # Step 1: Load license string
        license_string = load_license_string
        return :missing unless license_string

        # Step 2: Decode and verify JWT
        decoded_data = decode_license(license_string)
        return :invalid unless decoded_data

        # Step 3: Check plan validity
        plan_status = check_plan(decoded_data)
        return plan_status unless plan_status == :valid

        # Step 4: Check organization is present
        org_status = check_organization(decoded_data)
        return org_status unless org_status == :valid

        # Step 5: Check expiration
        check_expiration(decoded_data)
      end

      # Determines the license expiration time from the decoded JWT
      # @return [Time, nil] The expiration time or nil if not available
      def determine_license_expiration
        license_string = load_license_string
        return nil unless license_string

        decoded_data = decode_license(license_string)
        return nil unless decoded_data

        exp = decoded_data["exp"]
        return nil unless exp

        exp_time = if exp.is_a?(Numeric)
                     exp.to_i
                   else
                     Integer(exp)
                   end
        Time.at(exp_time)
      rescue ArgumentError, TypeError
        nil
      end

      # Determines the organization name from the decoded JWT
      # @return [String, nil] The organization name or nil if not available
      def determine_license_organization
        license_string = load_license_string
        return nil unless license_string

        decoded_data = decode_license(license_string)
        return nil unless decoded_data

        org = decoded_data["org"]
        return nil unless org.is_a?(String) && !org.strip.empty?

        org.strip
      end

      # Determines the license plan type from the decoded JWT
      # Returns nil for invalid/unknown plans - validation is handled by check_plan in license_status
      # @return [String, nil] The plan type or nil if not available/invalid
      def determine_license_plan
        license_string = load_license_string
        return nil unless license_string

        decoded_data = decode_license(license_string)
        return nil unless decoded_data

        plan = decoded_data["plan"]
        return nil unless plan && VALID_PLANS.include?(plan)

        plan
      end

      # Determines if attribution is required based on license data
      # Checks explicit attribution field first, then infers from plan type
      # @return [Boolean] True if attribution is required
      def determine_attribution_required
        license_string = load_license_string
        return false unless license_string

        decoded_data = decode_license(license_string)
        return false unless decoded_data

        # Check explicit attribution field first
        attribution = decoded_data["attribution"]
        return attribution if [true, false].include?(attribution)

        # Infer from plan type
        plan = decoded_data["plan"]
        return false unless plan.is_a?(String)

        ATTRIBUTION_REQUIRED_PLANS.include?(plan.strip)
      end

      # Loads license string from env var or file
      # @return [String, nil] License string or nil if not found
      def load_license_string
        # First try environment variable
        license = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", nil)
        return license if license && !license.strip.empty?

        # Then try config file
        config_path = Rails.root.join("config", "react_on_rails_pro_license.key")
        return unless config_path.exist?

        begin
          content = File.read(config_path).strip
          return nil if content.empty?

          content
        rescue StandardError
          nil
        end
      end

      # Decodes and verifies the JWT license
      # @return [Hash, nil] Decoded license data or nil if invalid
      def decode_license(license_string)
        JWT.decode(
          license_string,
          public_key,
          true, # verify signature - NEVER set to false!
          # Enforce RS256 algorithm only to prevent "alg=none" and downgrade attacks
          algorithm: "RS256",
          verify_expiration: false # we handle expiration manually
        ).first
      rescue StandardError
        nil
      end

      # Checks if the license plan is valid for production use
      # Licenses without a plan field are considered valid (backwards compatibility with old paid licenses)
      # Plans in VALID_PLANS are valid; all other plans (e.g., "free") are invalid
      # @return [Symbol] :valid or :invalid
      def check_plan(decoded_data)
        plan = decoded_data["plan"]
        return :valid unless plan # No plan field = valid (backwards compat with old paid licenses)
        return :valid if VALID_PLANS.include?(plan)

        :invalid
      end

      # Checks if the license has a valid organization name
      # Organization name is required for all licenses
      # @return [Symbol] :valid or :invalid
      def check_organization(decoded_data)
        org = decoded_data["org"]
        return :invalid unless org.is_a?(String) && !org.strip.empty?

        :valid
      end

      # Checks if the license is expired
      # @return [Symbol] :valid, :expired, or :invalid (if exp field missing or non-numeric)
      def check_expiration(license)
        return :invalid unless license["exp"]

        # Safely convert exp to Integer, handling non-numeric values
        exp_time = if license["exp"].is_a?(Numeric)
                     license["exp"].to_i
                   else
                     Integer(license["exp"])
                   end

        current_time = Time.now.to_i
        return :expired if current_time >= exp_time

        :valid
      rescue ArgumentError, TypeError
        # Non-numeric or unconvertible exp value
        :invalid
      end

      def public_key
        ReactOnRailsPro::LicensePublicKey::KEY
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
