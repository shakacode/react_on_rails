RelaySchema = GraphQL::Schema.new(query: QueryType)

# Responsible for dumping Schema.json to app/assets/javascripts/relay/
module RelaySchemaHelpers
  # Schema.json location
  SCHEMA_DIR  = Rails.root.join('app/assets/javascripts/relay/')
  SCHEMA_PATH = File.join(SCHEMA_DIR, 'schema.json')

  def execute_introspection_query
    # Cache the query result
    Rails.cache.fetch checksum do
      RelaySchema.execute GraphQL::Introspection::INTROSPECTION_QUERY
    end
  end

  def checksum
    files   = Dir["app/graph/**/*.rb"].reject { |f| File.directory?(f) }
    content = files.map { |f| File.read(f) }.join
    Digest::SHA256.hexdigest(content).to_s
  end

  def dump_schema
    # Generate the schema on start/reload
    FileUtils.mkdir_p SCHEMA_DIR
    result = JSON.pretty_generate(RelaySchema.execute_introspection_query)
    unless File.exists?(SCHEMA_PATH) && File.read(SCHEMA_PATH) == result
      File.write(SCHEMA_PATH, result)
    end
  end
end

RelaySchema.extend RelaySchemaHelpers
