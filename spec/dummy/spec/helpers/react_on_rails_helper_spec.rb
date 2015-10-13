require "rails_helper"

describe ReactOnRailsHelper, type: :helper do
  describe "#sanitized_props_string(props)" do
    let(:hash) do
      {
        hello: "world",
        free: "of charge",
        x: "</script><script>alert('foo')</script>"
      }
    end

    let(:hash_sanitized) do
      "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"\\u003c/script\\u003e\\u003cscrip"\
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
    end

    let(:hash_unsanitized) do
      "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
    end

    it "converts a hash to JSON and escapes </script>" do
      sanitized = helper.sanitized_props_string(hash)
      expect(sanitized).to eq(hash_sanitized)
    end

    it "leaves a string alone that does not contain xss tags" do
      sanitized = helper.sanitized_props_string(hash_sanitized)
      expect(sanitized).to eq(hash_sanitized)
    end

    it "fixes a string alone that contain xss tags" do
      sanitized = helper.sanitized_props_string(hash_unsanitized)
      expect(sanitized).to eq(hash_sanitized)
    end
  end
end
