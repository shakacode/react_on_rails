Rake::Task["assets:precompile"].enhance do
  Rake::Task["assets:symlink_non_digested_assets"].invoke
end

namespace :assets do
  task symlink_non_digested_assets: :"assets:environment" do
    manifest_path = Dir.glob(File.join(Rails.root, 'public/assets/.sprockets-manifest-*.json'))
                        .first
    manifest_data = JSON.load(File.new(manifest_path))

    manifest_data["assets"].each do |logical_path, digested_path|
      regex = ReactOnRails.configuration.symlink_non_digested_assets_regex
      if logical_path =~ regex
        full_digested_path = File.join(Rails.root, 'public/assets', digested_path)
        full_nondigested_path = File.join(Rails.root, 'public/assets', logical_path)
        puts "Symlinking #{full_digested_path} to #{full_nondigested_path}"
        FileUtils.ln_s full_digested_path, full_nondigested_path, force: true
      end
    end
  end
end
