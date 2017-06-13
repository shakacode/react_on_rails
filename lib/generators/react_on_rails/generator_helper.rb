# frozen_string_literal: true

require "rainbow"
require_relative "option_helper"

module GeneratorHelper
  def src_file_exists?(file)
    File.exist?(File.join("templates", file))
  end

  # Takes a relative path from the destination root, such as `.gitignore` or `app/assets/javascripts/application.js`
  def dest_file_exists?(file)
    dest_file = File.join(destination_root, file)
    File.exist?(dest_file) ? dest_file : nil
  end

  def dest_dir_exists?(dir)
    dest_dir = File.join(destination_root, dir)
    Dir.exist?(dest_dir) ? dest_dir : nil
  end

  def setup_file_error(file, data)
    # rubocop:disable Layout/IndentHeredoc
    <<-MSG
#{file} was not found.
Please add the following content to your #{file} file:
#{data}
    MSG
    # rubocop:enable Layout/IndentHeredoc
  end

  def create_client_directories(*dir_names)
    dir_names.each do |dir_name|
      dest_dir = "client/app/bundles/HelloWorld/#{dir_name}"
      empty_directory \
        convert_filename_to_use_example_page_name(dest_dir)
    end
  end

  def empty_directory_with_keep_file(destination, config = {})
    empty_directory(destination, config)
    keep_file(destination)
  end

  def keep_file(destination)
    create_file("#{destination}/.keep") unless options[:skip_keeps]
  end

  # As opposed to Rails::Generators::Testing.create_link, which creates a link pointing to
  # source_root, this symlinks a file in destination_root to a file also in
  # destination_root.
  def symlink_dest_file_to_dest_file(target, link)
    target_pathname = Pathname.new(File.join(destination_root, target))
    link_pathname = Pathname.new(File.join(destination_root, link))

    link_directory = link_pathname.dirname
    link_basename = link_pathname.basename
    target_relative_path = target_pathname.relative_path_from(link_directory)

    `cd #{link_directory} && ln -s #{target_relative_path} #{link_basename}`
  end

  def copy_file_and_missing_parent_directories(source_file, destination_file = nil)
    destination_file = source_file unless destination_file
    destination_path = Pathname.new(destination_file)
    parent_directories = destination_path.dirname
    empty_directory(parent_directories) unless dest_dir_exists?(parent_directories)
    copy_file source_file, destination_file
  end

  def copy_or_template(src_file, dest_file)
    if src_file_exists?(src_file)
      copy_file(src_file, dest_file)
      return
    end

    src_template = "#{src_file}.tt"
    template(src_template, dest_file)
  end
end
