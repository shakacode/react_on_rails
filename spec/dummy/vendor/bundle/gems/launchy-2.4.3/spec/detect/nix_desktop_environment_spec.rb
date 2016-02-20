require 'spec_helper'

describe Launchy::Detect::NixDesktopEnvironment do

  before do
    Launchy.reset_global_options
  end

  after do
    Launchy.reset_global_options
  end

  it "can detect the desktop environment of a KDE machine using ENV['KDE_FULL_SESSION']" do
    ENV.delete( "KDE_FULL_SESSION" )
    ENV["KDE_FULL_SESSION"] = "launchy-test"
    kde = Launchy::Detect::NixDesktopEnvironment::Kde
    nix_env = Launchy::Detect::NixDesktopEnvironment.detect
    nix_env.must_equal( kde )
    nix_env.browser.must_equal( kde.browser )
    ENV.delete( 'KDE_FULL_SESSION' )
  end

  it "returns false for XFCE if xprop is not found" do
    Launchy.host_os = "linux"
    Launchy::Detect::NixDesktopEnvironment::Xfce.is_current_desktop_environment?.must_equal( false )
  end

  it "returns NotFound if it cannot determine the *nix desktop environment" do
    Launchy.host_os = "linux"
    ENV.delete( "KDE_FULL_SESSION" )
    ENV.delete( "GNOME_DESKTOP_SESSION_ID" )
    not_found = Launchy::Detect::NixDesktopEnvironment.detect
    not_found.must_equal( Launchy::Detect::NixDesktopEnvironment::NotFound )
    not_found.browser.must_equal( Launchy::Argv.new )
  end
end
