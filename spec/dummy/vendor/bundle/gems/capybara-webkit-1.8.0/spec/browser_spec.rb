require 'spec_helper'
require 'self_signed_ssl_cert'
require 'stringio'
require 'capybara/webkit/driver'
require 'socket'
require 'base64'

describe Capybara::Webkit::Browser do

  let(:connection) { Capybara::Webkit::Connection.new }
  let(:browser) { Capybara::Webkit::Browser.new(connection) }

  describe "forking", skip_on_windows: true, skip_on_jruby: true do
    it "only shuts down the server from the main process" do
      browser.reset!
      pid = fork {}
      Process.wait(pid)
      expect { browser.reset! }.not_to raise_error
    end
  end

  it "doesn't try to read an empty response" do
    connection = double("connection")
    connection.stub(:puts)
    connection.stub(:print)
    connection.stub(:gets).and_return("ok\n", "0\n")
    connection.stub(:read).and_raise(StandardError.new("tried to read empty response"))

    browser = Capybara::Webkit::Browser.new(connection)

    expect { browser.visit("/") }.not_to raise_error
  end

  describe '#command' do
    context 'non-ok response' do
      it 'raises an error of given class' do
        error_json = '{"class": "ClickFailed"}'

        connection.should_receive(:gets).ordered.and_return 'error'
        connection.should_receive(:gets).ordered.and_return error_json.bytesize
        connection.stub read: error_json

        expect { browser.command 'blah', 'meh' }.to raise_error(Capybara::Webkit::ClickFailed)
      end
    end
  end
end
