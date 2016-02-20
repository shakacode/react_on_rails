require 'sprockets'
require 'coffee-script'

Root = File.expand_path("../..", __FILE__)

Assets = Sprockets::Environment.new do |env|
  env.append_path File.join(Root, "lib", "assets", "javascripts")
end

class SlowResponse
  CHUNKS = ['<html><body>', '.'*50, '.'*20, '<a href="/index.html">Home</a></body></html>']

  def call(env)
    [200, headers, self]
  end

  def each
    CHUNKS.each do |part|
      sleep rand(0.3..0.8)
      yield part
    end
  end

  def length
    CHUNKS.join.length
  end

  def headers
    { "Content-Length" => length.to_s, "Content-Type" => "text/html", "Cache-Control" => "no-cache, no-store, must-revalidate" }
  end
end

map "/js" do
  run Assets
end

map "/500" do
  # throw Internal Server Error (500)
end

map "/withoutextension" do
  run Rack::File.new(File.join(Root, "test", "withoutextension"), "Content-Type" => "text/html")
end

map "/slow-response" do
  run SlowResponse.new
end

map "/bounce" do
  run Proc.new{ [200, { "X-XHR-Redirected-To" => "redirect1.html", "Content-Type" => "text/html" }, File.open( File.join( Root, "test", "redirect1.html" ) ) ] }
end

map "/" do
  run Rack::Directory.new(File.join(Root, "test"))
end
