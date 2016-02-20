require 'compass/import-once/activate'

http_path       = "/"
css_dir         = "stylesheets"
sass_dir        = "sass"
images_dir      = "images"
javascripts_dir = "javascripts"

sourcemap     = true
output_style  = :compressed
sass_options  = { cache: false }
line_comments = false

require 'autoprefixer-rails'

on_stylesheet_saved do |file|
  css = File.read(file)
  map = file + '.map'

  if File.exists? map
    result = AutoprefixerRails.process(css,
      from: file,
      to:   file,
      map:  { prev: File.read(map), inline: false })
    File.open(file, 'w') { |io| io << result.css }
    File.open(map,  'w') { |io| io << result.map }
  else
    File.open(file, 'w') { |io| io << AutoprefixerRails.process(css) }
  end
end
