eval <<EOF, TOPLEVEL_BINDING, File.join(RbConfig::CONFIG['rubylibdir'], 'fake.rb'), 1

module Test
  def self.bar(*args)
    yield
  rescue => e
    raise e
  end
end

EOF

Test.bar{ raise "reraise-exception" }
