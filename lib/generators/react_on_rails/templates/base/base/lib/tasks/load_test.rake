namespace :load_test do
  desc "Load test with apache benchmark"
  task :run, [:url, :count] do |_, args|
    url = args[:url] || "http://localhost:3000/hello_world"
    count = args[:count] || 500
    system("ab -c 10 -n #{count} #{url}")
  end
end
