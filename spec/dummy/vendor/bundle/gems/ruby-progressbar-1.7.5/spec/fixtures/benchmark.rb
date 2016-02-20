# bundle exec ruby-prof --printer=graph_html
#                       --file=../results.html
#                       --require 'ruby-progressbar'
#                       --sort=total ./spec/fixtures/benchmark.rb

total  = 100_000
# output = File.open('/Users/jfelchner/Downloads/benchmark.txt', 'w+')
output = $stdout

# Progressbar gem
# bar = ProgressBar.new('Progress', total)
#
# total.times do |i|
#   bar.inc
# end
#
# bar.finish

# Ruby/ProgressBar
bar = ProgressBar.create(:output => output,
                         :length => 80,
                         :start  => 0,
                         :total  => total)

total.times do |_i|
  # bar.log i
  bar.increment
end
