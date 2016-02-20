eval <<EOF, TOPLEVEL_BINDING, File.join(RbConfig::CONFIG['rubylibdir'], 'fake.rb'), 1

module Test
  def self.foo(*args)
    args.each do |a|
      raise ArgumentError, "no :baz please" if a == :baz
    end
  end
end

EOF

Test.foo(:baz)
