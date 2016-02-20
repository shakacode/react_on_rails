shared_examples_for "output writer" do
  before do
    @read, @write = IO.pipe
  end

  let(:browser) do
    connection = Capybara::Webkit::Connection.new(:stderr => @write)
    Capybara::Webkit::Browser.new(connection)
  end

  let(:stderr) do
    @write.close
    @read.read
  end
end
