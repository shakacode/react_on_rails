module FixturesHelper
  def self.fixtures_dir
    File.join(__dir__, "..", "fixtures")
  end

  def self.get_file(file)
    File.join(fixtures_dir, *Array(file))
  end
end
