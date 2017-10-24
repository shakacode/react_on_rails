# You can run these commands in separate shells
web: rails s -p 3000

# Next line runs a watch process with webpack to compile the changed files.
# When making frequent changes to client side assets, you will prefer building webpack assets
# upon saving rather than when you refresh your browser page.
client: sh -c 'rm -rf public/packs/* || true && bundle exec rake react_on_rails:locale && bin/webpack -w'
