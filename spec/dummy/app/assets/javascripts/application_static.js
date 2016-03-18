// This file is used in production and tests to serve generated JS assets.
//
// In development mode, we use either:
// Procfile.static: Load static assets
// Procfile.hot: Use the Webpack Dev Server to provide assets. This allows for hot reloading of
// the JS and CSS via HMR.
//
// To understand which one is used, see app/views/layouts/application.html.erb

// These assets are located in app/assets/webpack directory
// Its is CRITICAL for Turbolinks 2.x that webpack/vendor-bundle must be BEFORE turbolinks
// since it is exposing jQuery and jQuery-ujs

// NOTE: See config/initializers/assets.rb for some critical configuration regarding sprockets.
// Basically, in HOT mode, we do not include this file for
// Rails.application.config.assets.precompile

//= require vendor-bundle
//= require app-bundle

// Non-webpack assets include turbolinks and these are loaded in the "hot" mode as well.
//= require application_non_webpack
