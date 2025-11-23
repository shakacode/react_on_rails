# frozen_string_literal: true

module ReactOnRailsPro
  module V8LogProcessor
    def self.process_v8_logs(keep_files, output_dir)
      FileUtils.mkdir_p(output_dir)
      log_files = Dir.glob("isolate-*.log")
      return unless user_confirms_processing(log_files)

      move_files(log_files, output_dir)
      processed_count = process_each_file(log_files, output_dir)
      delete_files(log_files, output_dir) unless keep_files
      puts "#{processed_count} files have been processed."
    end

    def self.move_files(log_files, log_dir)
      log_files.each { |file| FileUtils.mv(file, log_dir) }
    end

    # Processes each log file into a separate JSON profile and logs progress.
    # Returns the number of files processed.
    def self.process_each_file(log_files, log_dir)
      total_files = log_files.length
      log_files.each_with_index do |file, index|
        filename = File.basename(file, ".log")
        json_filename = "#{filename}.profile.v8log.json"
        Dir.chdir(log_dir) do
          system("node --prof-process --preprocess -j #{File.basename(file)} > #{json_filename}")
        end
        puts "Processed file #{index + 1} of #{total_files} (#{((index + 1).to_f / total_files * 100).round(2)}%)"
      end
      total_files # Return the number of processed files
    end

    def self.delete_files(log_files, log_dir)
      log_files.each { |file| FileUtils.rm(File.join(log_dir, File.basename(file))) }
    end

    # Warns if many files and asks for user confirmation to proceed.
    def self.user_confirms_processing(log_files)
      if log_files.count > 100
        puts "Warning: There are many log files (#{log_files.count}), this may take some time."
        puts "Do you want to continue? [y/N]: "
        response = $stdin.gets.chomp.downcase
        return response == "y"
      end
      true
    end
  end
end
