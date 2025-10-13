# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# React on Rails Pro License Public Key Management Tasks
#
# Usage:
#   rake react_on_rails_pro:update_public_key              # From production (shakacode.com)
#   rake react_on_rails_pro:update_public_key[local]       # From localhost:8788
#   rake react_on_rails_pro:update_public_key[custom.com]  # From custom hostname
#   rake react_on_rails_pro:verify_public_key              # Verify current configuration
#   rake react_on_rails_pro:public_key_help                # Show help

namespace :react_on_rails_pro do
  desc "Update the public key for React on Rails Pro license validation"
  task :update_public_key, [:source] do |_task, args|
    source = args[:source] || "production"

    # Determine the API URL based on the source
    api_url = case source
              when "local", "localhost"
                # Use the default local URL created by the Cloudflare Wrangler tool when the worker is run locally
                "http://localhost:8788/api/public-key"
              when "production", "prod"
                "https://www.shakacode.com/api/public-key"
              else
                # Check if it's a custom URL or hostname
                if source.start_with?("http://", "https://")
                  # Full URL provided
                  source.end_with?("/api/public-key") ? source : "#{source}/api/public-key"
                else
                  # Just a hostname provided
                  "https://#{source}/api/public-key"
                end
              end

    puts "Fetching public key from: #{api_url}"

    begin
      uri = URI(api_url)
      response = Net::HTTP.get_response(uri)

      if response.code != "200"
        puts "❌ Failed to fetch public key. HTTP Status: #{response.code}"
        puts "Response: #{response.body}"
        exit 1
      end

      data = JSON.parse(response.body)
      public_key = data["publicKey"]

      if public_key.nil? || public_key.empty?
        puts "❌ No public key found in response"
        exit 1
      end

      # TODO: Add a prepublish check to ensure this key matches the latest public key from the API.
      # This should be implemented after publishing the API endpoint on the ShakaCode website.
      # Update Ruby public key file
      ruby_file_path = File.join(File.dirname(__FILE__), "..", "lib", "react_on_rails_pro", "license_public_key.rb")
      ruby_content = <<~RUBY.strip_heredoc
        # frozen_string_literal: true

        module ReactOnRailsPro
          module LicensePublicKey
            # ShakaCode's public key for React on Rails Pro license verification
            # The private key corresponding to this public key is held by ShakaCode
            # and is never committed to the repository
            # Last updated: #{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")}
            # Source: #{api_url}
            #
            # You can update this public key by running the rake task:
            #   react_on_rails_pro:update_public_key
            # This task fetches the latest key from the API endpoint:
            #   http://shakacode.com/api/public-key
            KEY = OpenSSL::PKey::RSA.new(<<~PEM.strip.strip_heredoc)
              #{public_key.strip}
            PEM
          end
        end
      RUBY

      File.write(ruby_file_path, ruby_content)
      puts "✅ Updated Ruby public key: #{ruby_file_path}"

      # Update Node/TypeScript public key file
      node_file_path = File.join(File.dirname(__FILE__), "..", "packages", "node-renderer", "src", "shared", "licensePublicKey.ts")
      node_content = <<~TYPESCRIPT
        // ShakaCode's public key for React on Rails Pro license verification
        // The private key corresponding to this public key is held by ShakaCode
        // and is never committed to the repository
        // Last updated: #{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")}
        // Source: #{api_url}
        //
        // You can update this public key by running the rake task:
        //   react_on_rails_pro:update_public_key
        // This task fetches the latest key from the API endpoint:
        //   http://shakacode.com/api/public-key
        export const PUBLIC_KEY = `#{public_key.strip}`;
      TYPESCRIPT

      File.write(node_file_path, node_content)
      puts "✅ Updated Node public key: #{node_file_path}"

      puts "\n✅ Successfully updated public keys from #{api_url}"
      puts "\nPublic key info:"
      puts "  Algorithm: #{data['algorithm'] || 'RSA-2048'}"
      puts "  Format: #{data['format'] || 'PEM'}"
      puts "  Usage: #{data['usage'] || 'React on Rails Pro license verification'}"
    rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
      puts "❌ Network error: #{e.message}"
      puts "Please check your internet connection and the API URL."
      exit 1
    rescue JSON::ParserError => e
      puts "❌ Failed to parse JSON response: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  desc "Show usage examples for updating the public key"
  task :public_key_help do
    puts <<~HELP
      React on Rails Pro - Public Key Management
      ==========================================

      Update public key from different sources:

      1. From production (ShakaCode's official server):
         rake react_on_rails_pro:update_public_key
         rake react_on_rails_pro:update_public_key[production]

      2. From local development server:
         rake react_on_rails_pro:update_public_key[local]

      3. From a custom hostname:
         rake react_on_rails_pro:update_public_key[staging.example.com]

      4. From a custom full URL:
         rake react_on_rails_pro:update_public_key[https://api.example.com/api/public-key]

      Verify current public key:
         rake react_on_rails_pro:verify_public_key

      Note: The public key is used to verify JWT licenses for React on Rails Pro.
            The corresponding private key is held securely by ShakaCode.
    HELP
  end
end
