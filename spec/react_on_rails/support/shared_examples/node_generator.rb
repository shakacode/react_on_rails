shared_examples "node_generator" do
  it "copies base redux files" do
    %w(client/node/server.js
       client/node/package.json).each { |file| assert_file(file) }
  end
end
