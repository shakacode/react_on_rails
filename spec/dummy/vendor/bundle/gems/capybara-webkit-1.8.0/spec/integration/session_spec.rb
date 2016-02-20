# -*- encoding: UTF-8 -*-

require 'spec_helper'
require 'capybara/webkit'

module TestSessions
  Webkit = Capybara::Session.new(:reusable_webkit, TestApp)
end

Capybara::SpecHelper.run_specs TestSessions::Webkit, "webkit"

describe Capybara::Session do
  include AppRunner
  include Capybara::RSpecMatchers

  subject { Capybara::Session.new(:reusable_webkit, @app) }
  after { subject.reset! }

  context "slow javascript app" do
    before(:all) do
      @app = lambda do |env|
        body = <<-HTML
          <html><body>
            <form action="/next" id="submit_me"><input type="submit" value="Submit" /></form>
            <p id="change_me">Hello</p>

            <script type="text/javascript">
              var form = document.getElementById('submit_me');
              form.addEventListener("submit", function (event) {
                event.preventDefault();
                setTimeout(function () {
                  document.getElementById("change_me").innerHTML = 'Good' + 'bye';
                }, 500);
              });
            </script>
          </body></html>
        HTML
        [200,
          { 'Content-Type' => 'text/html', 'Content-Length' => body.length.to_s },
          [body]]
      end
    end

    around do |example|
      Capybara.using_wait_time(1) do
        example.run
      end
    end

    it "waits for a request to load" do
      subject.visit("/")
      subject.find_button("Submit").click
      subject.should have_content("Goodbye");
    end
  end

  context "simple app" do
    before(:all) do
      @app = lambda do |env|
        body = <<-HTML
          <html><body>
            <strong>Hello</strong>
            <span>UTF8文字列</span>
            <input type="button" value="ボタン" />
            <a href="about:blank">Link</a>
          </body></html>
        HTML
        [200,
          { 'Content-Type' => 'text/html; charset=UTF-8', 'Content-Length' => body.length.to_s },
          [body]]
      end
    end

    before do
      subject.visit("/")
    end

    it "inspects nodes" do
      subject.all(:xpath, "//strong").first.inspect.should include("strong")
    end

    it "can read utf8 string" do
      utf8str = subject.all(:xpath, "//span").first.text
      utf8str.should eq('UTF8文字列')
    end

    it "can click utf8 string" do
      subject.click_button('ボタン')
    end

    it "raises an ElementNotFound error when the selector scope is no longer valid" do
      subject.within('//body') do
        subject.click_link 'Link'
        lambda { subject.find('//strong') }.should raise_error(Capybara::ElementNotFound)
      end
    end
  end

  context "response headers with status code" do
    before(:all) do
      @app = lambda do |env|
        params = ::Rack::Utils.parse_query(env['QUERY_STRING'])
        if params["img"] == "true"
          body = 'not found'
          return [404, { 'Content-Type' => 'image/gif', 'Content-Length' => body.length.to_s }, [body]]
        end
        body = <<-HTML
          <html>
            <body>
              <img src="?img=true">
            </body>
          </html>
        HTML
        [200,
          { 'Content-Type' => 'text/html', 'Content-Length' => body.length.to_s, 'X-Capybara' => 'WebKit'},
          [body]]
      end
    end

    it "should get status code" do
      subject.visit '/'
      subject.status_code.should eq 200
    end

    it "should reset status code" do
      subject.visit '/'
      subject.status_code.should eq 200
      subject.reset!
      subject.status_code.should eq 0
    end

    it "should get response headers" do
      subject.visit '/'
      subject.response_headers['X-Capybara'].should eq 'WebKit'
    end

    it "should reset response headers" do
      subject.visit '/'
      subject.response_headers['X-Capybara'].should eq 'WebKit'
      subject.reset!
      subject.response_headers['X-Capybara'].should eq nil
    end
  end

  context "slow iframe app" do
    before do
      @app = Class.new(ExampleApp) do
        get '/' do
          <<-HTML
          <html>
          <head>
          <script>
            function hang() {
              xhr = new XMLHttpRequest();
              xhr.onreadystatechange = function() {
                if(xhr.readyState == 4){
                  document.getElementById('p').innerText = 'finished'
                }
              }
              xhr.open('GET', '/slow', true);
              xhr.send();
              document.getElementById("f").src = '/iframe';
              return false;
            }
          </script>
          </head>
          <body>
            <a href="#" onclick="hang()">Click Me!</a>
            <iframe src="about:blank" id="f"></iframe>
            <p id="p"></p>
          </body>
          </html>
          HTML
        end

        get '/slow' do
          sleep 1
          status 204
        end

        get '/iframe' do
          status 204
        end
      end
    end

    it "should not hang the server" do
      subject.visit("/")
      subject.click_link('Click Me!')
      Capybara.using_wait_time(5) do
        subject.should have_content("finished")
      end
    end
  end

  context "session app" do
    before do
      @app = Class.new(ExampleApp) do
        enable :sessions
        get '/' do
          <<-HTML
          <html>
          <body>
            <form method="post" action="/sign_in">
              <input type="text" name="username">
              <input type="password" name="password">
              <input type="submit" value="Submit">
            </form>
          </body>
          </html>
          HTML
        end

        post '/sign_in' do
          session[:username] = params[:username]
          session[:password] = params[:password]
          redirect '/'
        end

        get '/other' do
          <<-HTML
          <html>
          <body>
            <p>Welcome, #{session[:username]}.</p>
          </body>
          </html>
          HTML
        end
      end
    end

    it "should not start queued commands more than once" do
      subject.visit('/')
      subject.fill_in('username', with: 'admin')
      subject.fill_in('password', with: 'temp4now')
      subject.click_button('Submit')
      subject.visit('/other')
      subject.should have_content('admin')
    end
  end

  context "iframe app" do
    before(:all) do
      @app = Class.new(ExampleApp) do
        get '/' do
          <<-HTML
            <!DOCTYPE html>
            <html>
            <body>
              <h1>Main Frame</h1>
              <iframe src="/a" name="a_frame" width="500" height="500"></iframe>
            </body>
            </html>
          HTML
        end

        get '/a' do
          <<-HTML
            <!DOCTYPE html>
            <html>
            <body>
              <h1>Page A</h1>
              <iframe src="/b" name="b_frame" width="500" height="500"></iframe>
            </body>
            </html>
          HTML
        end

        get '/b' do
          <<-HTML
            <!DOCTYPE html>
            <html>
            <body>
              <h1>Page B</h1>
              <form action="/c" method="post">
              <input id="button" name="commit" type="submit" value="B Button">
              </form>
            </body>
            </html>
          HTML
        end

        post '/c' do
          <<-HTML
            <!DOCTYPE html>
            <html>
            <body>
              <h1>Page C</h1>
            </body>
            </html>
          HTML
        end
      end
    end

    it 'supports clicking an element offset from the viewport origin' do
      subject.visit '/'

      subject.within_frame 'a_frame' do
        subject.within_frame 'b_frame' do
          subject.click_button 'B Button'
          subject.should have_content('Page C')
        end
      end
    end

    it 'raises an error if an element is obscured when clicked' do
      subject.visit('/')

      subject.execute_script(<<-JS)
        var div = document.createElement('div');
        div.style.position = 'absolute';
        div.style.left = '0px';
        div.style.top = '0px';
        div.style.width = '100%';
        div.style.height = '100%';
        document.body.appendChild(div);
      JS

      subject.within_frame('a_frame') do
        subject.within_frame('b_frame') do
          lambda {
            subject.click_button 'B Button'
          }.should raise_error(Capybara::Webkit::ClickFailed)
        end
      end
    end
  end

  context 'click tests' do
    before(:all) do
      @app = Class.new(ExampleApp) do
        get '/' do
          <<-HTML
            <!DOCTYPE html>
            <html>
            <head>
            <style>
              body {
                width: 800px;
                margin: 0;
              }
              .target {
                width: 200px;
                height: 200px;
                float: left;
                margin: 100px;
              }
              #offscreen {
                position: absolute;
                left: -5000px;
              }
            </style>
            <body>
              <div id="one" class="target"></div>
              <div id="two" class="target"></div>
              <div id="offscreen"><a href="/" id="foo">Click Me</a></div>
              <form>
                <input type="checkbox" id="bar">
              </form>
              <div><a href="#"><i></i>Some link</a></div>
              <script type="text/javascript">
                var targets = document.getElementsByClassName('target');
                for (var i = 0; i < targets.length; i++) {
                  var target = targets[i];
                  target.onclick = function(event) {
                    this.setAttribute('data-click-x', event.clientX);
                    this.setAttribute('data-click-y', event.clientY);
                  };
                }
              </script>
            </body>
            </html>
          HTML
        end
      end
    end

    it 'clicks in the center of an element' do
      subject.visit('/')
      subject.find(:css, '#one').click
      subject.find(:css, '#one')['data-click-x'].should eq '199'
      subject.find(:css, '#one')['data-click-y'].should eq '199'
    end

    it 'clicks in the center of the viewable area of an element' do
      subject.visit('/')
      subject.driver.resize_window(200, 200)
      subject.find(:css, '#one').click
      subject.find(:css, '#one')['data-click-x'].should eq '149'
      subject.find(:css, '#one')['data-click-y'].should eq '99'
    end

    it 'does not raise an error when an anchor contains empty nodes' do
      subject.visit('/')
      lambda { subject.click_link('Some link') }.should_not raise_error
    end

    it 'scrolls an element into view when clicked' do
      subject.visit('/')
      subject.driver.resize_window(200, 200)
      subject.find(:css, '#two').click
      subject.find(:css, '#two')['data-click-x'].should_not be_nil
      subject.find(:css, '#two')['data-click-y'].should_not be_nil
    end

    it 'raises an error if an element is obscured when clicked' do
      subject.visit('/')

      subject.execute_script(<<-JS)
        var two = document.getElementById('two');
        two.style.position = 'absolute';
        two.style.left = '0px';
        two.style.top = '0px';
      JS

      expect {
        subject.find(:css, '#one').click
      }.to raise_error(Capybara::Webkit::ClickFailed) { |exception|
        exception.message.should =~ %r{Failed.*\[@id='one'\].*overlapping.*\[@id='two'\].*at position}
        screenshot_pattern = %r{A screenshot of the page at the time of the failure has been written to (.*)}
        exception.message.should =~ screenshot_pattern
        file = exception.message.match(screenshot_pattern)[1]
        File.exist?(file).should be_true
      }
    end

    it 'raises an error if a checkbox is obscured when checked' do
      subject.visit('/')

      subject.execute_script(<<-JS)
        var div = document.createElement('div');
        div.style.position = 'absolute';
        div.style.left = '0px';
        div.style.top = '0px';
        div.style.width = '100%';
        div.style.height = '100%';
        document.body.appendChild(div);
      JS

      lambda {
        subject.check('bar')
      }.should raise_error(Capybara::Webkit::ClickFailed)
    end

    it 'raises an error if an element is not visible when clicked' do
      ignore_hidden_elements = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      begin
        subject.visit('/')
        subject.execute_script "document.getElementById('foo').style.display = 'none'"
        lambda { subject.click_link "Click Me" }.should raise_error(
          Capybara::Webkit::ClickFailed,
          /\[@id='foo'\].*visible/
        )
      ensure
        Capybara.ignore_hidden_elements = ignore_hidden_elements
      end
    end

    it 'raises an error if an element is not in the viewport when clicked' do
      subject.visit('/')
      lambda { subject.click_link "Click Me" }.should raise_error(Capybara::Webkit::ClickFailed)
    end

    context "with wait time of 1 second" do
      around do |example|
        Capybara.using_wait_time(1) do
          example.run
        end
      end

      it "waits for an element to appear in the viewport when clicked" do
        subject.visit('/')
        subject.execute_script <<-JS
          setTimeout(function() {
            var offscreen = document.getElementById('offscreen')
            offscreen.style.left = '10px';
          }, 400);
        JS

        lambda { subject.click_link "Click Me" }.should_not raise_error
      end
    end
  end

  context 'styled upload app' do
    let(:session) do
      session_for_app do
        get '/render_form' do
          <<-HTML
            <html>
              <head>
                <style type="text/css">
                  #wrapper { position: relative; }
                  input[type=file] {
                    position: relative;
                    opacity: 0;
                    z-index: 2;
                    width: 50px;
                  }
                  #styled {
                    position: absolute;
                    top: 0;
                    left: 0;
                    z-index: 1;
                    width: 50px;
                  }
                </style>
              </head>
              <body>
                <form action="/submit" method="post" enctype="multipart/form-data">
                  <label for="file">File</label>
                  <div id="wrapper">
                    <input type="file" name="file" id="file" />
                    <div id="styled">Upload</div>
                  </div>
                  <input type="submit" value="Go" />
                </form>
              </body>
            </html>
          HTML
        end

        post '/submit' do
          contents = params[:file][:tempfile].read
          "You uploaded: #{contents}"
        end
      end
    end

    it 'attaches uploads' do
      file = Tempfile.new('example')
      file.write('Hello')
      file.flush

      session.visit('/render_form')
      session.attach_file 'File', file.path
      session.click_on 'Go'

      session.should have_text('Hello')
    end
  end
end
