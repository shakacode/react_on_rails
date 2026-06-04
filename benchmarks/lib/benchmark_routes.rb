# frozen_string_literal: true

require "open3"

# Routes that exist only to demonstrate mistakes / anti-patterns (linked from the
# dummy apps' sidebar as "Improperly defined…" / "Incorrectly …"). They are meant
# to error (and hard-500 in the Pro suite), so they are demos, not performance
# workloads — keep auto-discovery from sweeping them into the suite.
# Explicitly-requested routes (ROUTES=) are honored regardless.
NON_BENCHMARK_ROUTES = %w[
  /react_helmet_broken
  /context_function_return_jsx
  /pure_component_wrapped_in_function
].freeze

def route_has_required_params?(path)
  path_without_optional = path.gsub(/\([^)]*\)/, "")
  path_without_optional.include?(":")
end

def strip_optional_params(route)
  route.gsub(/\([^)]*\)/, "")
end

def sanitize_route_name(route)
  name = strip_optional_params(route).gsub(%r{^/}, "").tr("/", "_")
  name = "root" if name.empty?
  # Strip shell metacharacters and GitHub Actions artifact-name disallowed characters.
  name.gsub(/[":.<>|*?\r\n$`;&#!()\[\]{}]+/, "_").squeeze("_").gsub(/^_|_$/, "")
end

def benchmark_routes_from_rails_routes(app_dir)
  stdout, stderr, status = Open3.capture3(
    {
      # Match the benchmark server environment so route discovery sees the same
      # mounted engines and conditional routes as the production process.
      "RAILS_ENV" => "production",
      "NODE_ENV" => "production",
      "SECRET_KEY_BASE" => ENV.fetch("SECRET_KEY_BASE", "benchmark-secret-key-base")
    },
    "bundle",
    "exec",
    "rails",
    "routes",
    "--expanded",
    chdir: app_dir
  )
  warn stderr unless stderr.empty?
  raise "Failed to get routes from #{app_dir}" unless status.success?

  benchmark_routes_from_rails_routes_output(stdout)
end

def benchmark_routes_from_rails_routes_output(routes_output)
  routes = []
  current_route = {}

  routes_output.each_line do |line|
    stripped = line.strip

    case stripped
    when /\APrefix\s+\|\s*(.*)\z/
      current_route[:prefix] = Regexp.last_match(1)
    when /\AVerb\s+\|\s*(.*)\z/
      current_route[:verb] = Regexp.last_match(1)
    when /\AURI\s+\|\s*(.*)\z/
      current_route[:uri] = Regexp.last_match(1)
    when /\AController#Action\s+\|\s*(.*)\z/
      current_route[:controller_action] = Regexp.last_match(1)

      route = benchmark_route_from_rails_output(current_route)
      routes << route if route
      current_route = {}
    end
  end

  routes
end

def benchmark_controller_action?(controller_action)
  controller_action.start_with?("pages#", "react_router#")
end

def benchmark_routes_for_app(app_dir, explicit_routes)
  if explicit_routes
    # strip_optional_params keeps the BMF benchmark name (which bench.rb uses as-is) stable
    # across runs when callers pass routes copied from `rails routes` output containing "(.:format)".
    return explicit_routes.split(",").map(&:strip).reject(&:empty?).map do |route|
             strip_optional_params(normalize_route_path(route))
           end
  end

  benchmark_routes_from_rails_routes(app_dir)
end

def normalize_route_path(route)
  return route if route.start_with?("/")

  "/#{route}"
end

def benchmark_route_from_rails_output(route)
  return unless route[:verb] == "GET"
  return unless benchmark_controller_action?(route[:controller_action])

  path = route[:uri]
  return if route_has_required_params?(path)
  return if path.include?("_for_testing")

  normalized = normalize_route_path(strip_optional_params(path))
  return if NON_BENCHMARK_ROUTES.include?(normalized)

  normalized
end
