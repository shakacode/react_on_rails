# frozen_string_literal: true

module ReactOnRailsPro
  # Formats license verification output for the verify_license rake task.
  module LicenseTaskFormatter
    module_function

    def build_result(info)
      result = {
        status: info[:status].to_s,
        organization: info[:org],
        plan: info[:plan],
        expiration: info[:expiration]&.iso8601,
        attribution_required: info[:attribution_required],
        days_remaining: nil,
        renewal_required: false
      }
      add_expiration_fields(result, info)
    end

    def add_expiration_fields(result, info)
      return result unless info[:expiration]

      days_remaining = ((info[:expiration] - Time.now) / 86_400).ceil
      result[:days_remaining] = days_remaining
      result[:renewal_required] = info[:status] == :expired || days_remaining <= 30
      result
    end

    def print_text(result, info)
      puts "React on Rails Pro — License Status"
      puts "=" * 40
      print_status_line(info[:status])
      return if info[:status] == :missing

      print_details(result, info)
    end

    def print_status_line(status)
      puts "Status:        #{status.to_s.upcase}"
      return unless status == :missing

      puts ""
      puts "No license found. Set REACT_ON_RAILS_PRO_LICENSE"
      puts "or place a key file at config/react_on_rails_pro_license.key"
    end

    def print_details(result, info)
      puts "Organization:  #{info[:org] || '(unknown)'}"
      puts "Plan:          #{info[:plan] || '(unknown)'}"
      print_expiration(result, info)
      puts "Attribution:   #{info[:attribution_required] ? 'required' : 'not required'}"
      print_renewal_warning(result, info)
    end

    def print_expiration(result, info)
      return unless info[:expiration]

      puts "Expiration:    #{info[:expiration].strftime('%Y-%m-%d')}"
      puts "Days left:     #{result[:days_remaining]}"
    end

    def print_renewal_warning(result, info)
      return unless result[:renewal_required]

      puts ""
      if info[:status] == :expired
        puts "WARNING: License has expired. Renew at https://www.shakacode.com/react-on-rails-pro/"
      else
        puts "WARNING: License expires within 30 days. Renew at https://www.shakacode.com/react-on-rails-pro/"
      end
    end
  end
end
