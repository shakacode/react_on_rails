require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Objects" do
  before do
    stub_dotfile!
  end

  after do
    Object.instance_eval{ remove_const :Hello } if defined?(Hello)
  end

  describe "Formatting an object" do
    it "attributes" do
      class Hello
        attr_reader   :abra
        attr_writer   :ca
        attr_accessor :dabra

        def initialize
          @abra, @ca, @dabra = 1, 2, 3
        end
      end

      hello = Hello.new
      out = hello.ai(:plain => true, :raw => true)
      str = <<-EOS.strip
#<Hello:0x01234567
    attr_accessor :dabra = 3,
    attr_reader :abra = 1,
    attr_writer :ca = 2
>
EOS
      expect(out.gsub(/0x([a-f\d]+)/, "0x01234567")).to eq(str)
      expect(hello.ai(:plain => true, :raw => false)).to eq(hello.inspect)
    end

    it "instance variables" do
      class Hello
        def initialize
          @abra, @ca, @dabra = 1, 2, 3
        end
      end

      hello = Hello.new
      out = hello.ai(:plain => true, :raw => true)
      str = <<-EOS.strip
#<Hello:0x01234567
    @abra = 1,
    @ca = 2,
    @dabra = 3
>
EOS
      expect(out.gsub(/0x([a-f\d]+)/, "0x01234567")).to eq(str)
      expect(hello.ai(:plain => true, :raw => false)).to eq(hello.inspect)
    end

    it "attributes and instance variables" do
      class Hello
        attr_reader   :abra
        attr_writer   :ca
        attr_accessor :dabra

        def initialize
          @abra, @ca, @dabra = 1, 2, 3
          @scooby, @dooby, @doo = 3, 2, 1
        end
      end

      hello = Hello.new
      out = hello.ai(:plain => true, :raw => true)
      str = <<-EOS.strip
#<Hello:0x01234567
    @doo = 1,
    @dooby = 2,
    @scooby = 3,
    attr_accessor :dabra = 3,
    attr_reader :abra = 1,
    attr_writer :ca = 2
>
EOS
      expect(out.gsub(/0x([a-f\d]+)/, "0x01234567")).to eq(str)
      expect(hello.ai(:plain => true, :raw => false)).to eq(hello.inspect)
    end
  end
end
