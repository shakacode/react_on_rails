# frozen_string_literal: true

# Shared benchmark route discovery helpers.

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
  # Replace invalid characters: " : < > | * ? \r \n $ ` ; & ( ) [ ] { } ! #
  name.gsub(/[":.<>|*?\r\n$`;&#!()\[\]{}]+/, "_").squeeze("_").gsub(/^_|_$/, "")
end

def benchmark_routes_from_routes_file(routes_file)
  routes = []

  File.foreach(routes_file) do |line|
    stripped = line.strip

    case stripped
    when /\Aroot\s+"([^"]+)"\z/
      controller_action = Regexp.last_match(1)
      routes << "/" if benchmark_controller_action?(controller_action)
    when /\Aget\s+"([^"]+)"\s*=>\s*"([^"]+)"/
      path = Regexp.last_match(1)
      controller_action = Regexp.last_match(2)

      next unless benchmark_controller_action?(controller_action)
      next if route_has_required_params?(path)
      next if path.include?("_for_testing")

      routes << normalize_route_path(path)
    end
  end

  routes
end

def benchmark_controller_action?(controller_action)
  controller_action.start_with?("pages#", "react_router#")
end

def benchmark_routes_for_app(app_dir, explicit_routes)
  if explicit_routes
    return explicit_routes.split(",").map(&:strip).reject(&:empty?).map do |route|
             normalize_route_path(route)
           end
  end

  routes_file = File.join(app_dir, "config", "routes.rb")
  raise "Routes file not found: #{routes_file}" unless File.exist?(routes_file)

  benchmark_routes_from_routes_file(routes_file)
end

def normalize_route_path(route)
  return route if route.start_with?("/")

  "/#{route}"
end
