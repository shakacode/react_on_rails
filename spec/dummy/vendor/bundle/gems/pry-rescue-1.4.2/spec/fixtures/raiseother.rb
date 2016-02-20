eval <<EOF, TOPLEVEL_BINDING, File.join(RbConfig::CONFIG['rubylibdir'], 'fake.rb'), 1

module Test
  def self.baz(*args)
    yield
  rescue => e
    raiseother_exception
  end
end

EOF

Test.baz{ raise "reraise-exception" }
