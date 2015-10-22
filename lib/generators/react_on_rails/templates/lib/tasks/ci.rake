if Rails.env.development?
  # See tasks/linters.rake

  task :bundle_audit do
    puts Rainbow("Running security audit on gems (bundle_audit)").green
    Rake::Task["bundle_audit"].invoke
  end

  task :security_audit do
    puts Rainbow("Running security audit on code (brakeman)").green

    sh "brakeman --exit-on-warn --quiet -A -z"
  end

  namespace :ci do
    desc "Run all audits and tests"
    task all: [:environment, :lint, :spec, :bundle_audit, :security_audit] do
      begin
        puts Rainbow("PASSED").green
        puts ""
      rescue Exception => e
        puts "#{e}"
        puts Rainbow("FAILED").red
        puts ""
        raise(e)
      end
    end
  end

  task ci: "ci:all"

  task(:default).clear.enhance([:ci])
end
