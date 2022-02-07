# Procfile for development using HMR
# You can run these commands in separate shells
rails: bundle exec rails s -p 3000
wp-client: HMR=true bin/webpacker-dev-server
wp-server: HMR=true SERVER_BUNDLE_ONLY=yes bin/webpacker --watch
