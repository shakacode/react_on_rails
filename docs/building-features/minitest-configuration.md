# Minitest Configuration

The setup for minitest is the same as for rspec with the following difference.

Rather than calling `ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)`, instead you will do something like this:

```ruby
class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

Or maybe something like this, from the [minitest docs](https://github.com/seattlerb/minitest/blob/master/lib/minitest/test.rb#L119):

```ruby
module MyMinitestPlugin
  def before_setup
    super
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end

class MiniTest::Test
  include MyMinitestPlugin
end
```
