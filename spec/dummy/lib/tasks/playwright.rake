# frozen_string_literal: true

namespace :playwright do # rubocop:disable Metrics/BlockLength
  desc "Install Playwright browsers"
  task :install do
    sh "yarn playwright install --with-deps"
  end

  desc "Run Playwright E2E tests"
  task :test do
    sh "yarn test:e2e"
  end

  desc "Run Playwright tests in UI mode"
  task :ui do
    sh "yarn test:e2e:ui"
  end

  desc "Run Playwright tests in headed mode"
  task :headed do
    sh "yarn test:e2e:headed"
  end

  desc "Debug Playwright tests"
  task :debug do
    sh "yarn test:e2e:debug"
  end

  desc "Show Playwright test report"
  task :report do
    sh "yarn test:e2e:report"
  end

  desc "Run Playwright tests with specific project"
  task :chromium do
    sh "yarn playwright test --project=chromium"
  end

  task :firefox do
    sh "yarn playwright test --project=firefox"
  end

  task :webkit do
    sh "yarn playwright test --project=webkit"
  end

  desc "Clean Playwright artifacts"
  task :clean do
    sh "rm -rf playwright-report test-results"
  end
end

desc "Run Playwright E2E tests (alias for playwright:test)"
task e2e: "playwright:test"
