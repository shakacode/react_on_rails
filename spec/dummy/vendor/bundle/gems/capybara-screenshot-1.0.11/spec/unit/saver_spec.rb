require 'spec_helper'

describe Capybara::Screenshot::Saver do
  before(:all) do
    @original_drivers = Capybara::Screenshot.registered_drivers
    Capybara::Screenshot.registered_drivers[:default] = lambda {|driver, path| driver.render(path) }
  end

  after(:all) do
    Capybara::Screenshot.registered_drivers = @original_drivers
  end

  before do
    allow(Capybara::Screenshot).to receive(:capybara_root).and_return(capybara_root)
    Timecop.freeze(Time.local(2012, 6, 7, 8, 9, 10, 0))
  end

  let(:capybara_root) { '/tmp' }
  let(:timestamp) { '2012-06-07-08-09-10.000' }
  let(:file_basename) { "screenshot_#{timestamp}" }
  let(:screenshot_path) { "#{capybara_root}/#{file_basename}.png" }

  let(:driver_mock) { double('Capybara driver').as_null_object }
  let(:page_mock) { double('Capybara session page', :body => 'body', :driver => driver_mock).as_null_object }
  let(:capybara_mock) {
    double(Capybara).as_null_object.tap do |m|
      allow(m).to receive(:current_driver).and_return(:default)
      allow(m).to receive(:current_path).and_return('/')
    end
  }

  let(:saver) { Capybara::Screenshot::Saver.new(capybara_mock, page_mock) }

  context 'html filename with Capybara Version 1' do
    before do
      stub_const("Capybara::VERSION", '1')
    end

    it 'has a default format of "screenshot_Y-M-D-H-M-S.ms.html"' do
      expect(capybara_mock).to receive(:save_page).with('body', File.join(capybara_root, "#{file_basename}.html"))

      saver.save
    end

    it 'uses name argument as prefix' do
      saver = Capybara::Screenshot::Saver.new(capybara_mock, page_mock, true, 'custom-prefix')

      expect(capybara_mock).to receive(:save_page).with('body', File.join(capybara_root, "custom-prefix_#{timestamp}.html"))

      saver.save
    end
  end

  context 'html filename with Capybara Version 2' do
    before do
      stub_const("Capybara::VERSION", '2')
    end

    it 'has a default format of "screenshot_Y-M-D-H-M-S.ms.html"' do
      expect(capybara_mock).to receive(:save_page).with(File.join(capybara_root, "#{file_basename}.html"))

      saver.save
    end

    it 'uses name argument as prefix' do
      saver = Capybara::Screenshot::Saver.new(capybara_mock, page_mock, true, 'custom-prefix')

      expect(capybara_mock).to receive(:save_page).with(File.join(capybara_root, "custom-prefix_#{timestamp}.html"))

      saver.save
    end
  end

  context 'screenshot image path' do
    it 'is in capybara root output' do
      expect(driver_mock).to receive(:render).with(/^#{capybara_root}\//)

      saver.save
    end

    it 'has a default filename format of "screenshot_Y-M-D-H-M-S.ms.png"' do
      expect(driver_mock).to receive(:render).with(/#{file_basename}\.png$/)

      saver.save
    end

    it "does not append timestamp if append_timestamp is false " do
      default_config = Capybara::Screenshot.append_timestamp
      Capybara::Screenshot.append_timestamp = false
      expect(driver_mock).to receive(:render).with(/screenshot.png$/)

      saver.save
      Capybara::Screenshot.append_timestamp = default_config
    end

    it 'uses filename prefix argument as basename prefix' do
      saver = Capybara::Screenshot::Saver.new(capybara_mock, page_mock, true, 'custom-prefix')
      expect(driver_mock).to receive(:render).with(/#{capybara_root}\/custom-prefix_#{timestamp}\.png$/)

      saver.save
    end
  end

  it 'does not save html if false passed as html argument' do
    saver = Capybara::Screenshot::Saver.new(capybara_mock, page_mock, false)
    expect(capybara_mock).to_not receive(:save_page)

    saver.save
    expect(saver).to_not be_html_saved
  end

  it 'does not save if current_path is empty' do
    allow(capybara_mock).to receive(:current_path).and_return(nil)
    expect(capybara_mock).to_not receive(:save_page)
    expect(driver_mock).to_not receive(:render)

    saver.save
    expect(saver).to_not be_screenshot_saved
    expect(saver).to_not be_html_saved
  end

  context 'when saving a screenshot fails' do
    it 'still restores the original value of Capybara.save_and_open_page_path' do
      Capybara.save_and_open_page_path = 'tmp/bananas'

      expect(capybara_mock).to receive(:save_page).and_raise

      expect {
        saver.save
      }.to raise_error

      expect(Capybara.save_and_open_page_path).to eq('tmp/bananas')
    end
  end

  describe '#output_screenshot_path' do
    let(:saver) { Capybara::Screenshot::Saver.new(capybara_mock, page_mock) }

    before do
      allow(saver).to receive(:html_path) { 'page.html' }
      allow(saver).to receive(:screenshot_path) { 'screenshot.png' }
    end

    it 'outputs the path for the HTML screenshot' do
      allow(saver).to receive(:html_saved?).and_return(true)
      expect(saver).to receive(:output).with("HTML screenshot: page.html")
      saver.output_screenshot_path
    end

    it 'outputs the path for the Image screenshot' do
      allow(saver).to receive(:screenshot_saved?).and_return(true)
      expect(saver).to receive(:output).with("Image screenshot: screenshot.png")
      saver.output_screenshot_path
    end
  end

  describe "with selenium driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:selenium)
    end

    it 'saves via browser' do
      browser_mock = double('browser')
      expect(driver_mock).to receive(:browser).and_return(browser_mock)
      expect(browser_mock).to receive(:save_screenshot).with(screenshot_path)

      saver.save
      expect(saver).to be_screenshot_saved
    end
  end

  describe "with poltergeist driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:poltergeist)
    end

    it 'saves driver render with :full => true' do
      expect(driver_mock).to receive(:render).with(screenshot_path, {:full => true})

      saver.save
      expect(saver).to be_screenshot_saved
    end
  end

  describe "with poltergeist_billy driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:poltergeist_billy)
    end

    it 'saves driver render with :full => true' do
      expect(driver_mock).to receive(:render).with(screenshot_path, {:full => true})

      saver.save
      expect(saver).to be_screenshot_saved
    end
  end

  describe "with webkit driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:webkit)
    end

    context 'has render method' do
      before do
        allow(driver_mock).to receive(:respond_to?).with(:'save_screenshot').and_return(false)
      end

      it 'saves driver render' do
        expect(driver_mock).to receive(:render).with(screenshot_path)

        saver.save
        expect(saver).to be_screenshot_saved
      end
    end

    context 'has save_screenshot method' do
      let(:webkit_options){ {width: 800, height: 600} }

      before do
        allow(driver_mock).to receive(:respond_to?).with(:'save_screenshot').and_return(true)
      end

      it 'saves driver render' do
        expect(driver_mock).to receive(:save_screenshot).with(screenshot_path, {})

        saver.save
        expect(saver).to be_screenshot_saved
      end

      it 'passes webkit_options to driver' do
        allow(Capybara::Screenshot).to receive(:webkit_options).and_return( webkit_options )
        expect(driver_mock).to receive(:save_screenshot).with(screenshot_path, webkit_options)

        saver.save
        expect(saver).to be_screenshot_saved
      end
    end
  end

  describe "with webkit debug driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:webkit_debug)
    end

    context 'has render method' do
      before do
        allow(driver_mock).to receive(:respond_to?).with(:'save_screenshot').and_return(false)
      end

      it 'saves driver render' do
        expect(driver_mock).to receive(:render).with(screenshot_path)

        saver.save
        expect(saver).to be_screenshot_saved
      end
    end

    context 'has save_screenshot method' do
      let(:webkit_options){ {width: 800, height: 600} }

      before do
        allow(driver_mock).to receive(:respond_to?).with(:'save_screenshot').and_return(true)
      end

      it 'saves driver render' do
        expect(driver_mock).to receive(:save_screenshot).with(screenshot_path, {})

        saver.save
        expect(saver).to be_screenshot_saved
      end

      it 'passes webkit_options to driver' do
        allow(Capybara::Screenshot).to receive(:webkit_options).and_return( webkit_options )
        expect(driver_mock).to receive(:save_screenshot).with(screenshot_path, webkit_options)

        saver.save
        expect(saver).to be_screenshot_saved
      end
    end
  end

  describe "with unknown driver" do
    before do
      allow(capybara_mock).to receive(:current_driver).and_return(:unknown)
      allow(saver).to receive(:warn).and_return(nil)
    end

    it 'saves driver render' do
      expect(driver_mock).to receive(:render).with(screenshot_path)

      saver.save
      expect(saver).to be_screenshot_saved
    end

    it 'outputs warning about unknown results' do
      # Not pure mock testing
      expect(saver).to receive(:warn).with(/screenshot driver for 'unknown'.*unknown results/).and_return(nil)

      saver.save
      expect(saver).to be_screenshot_saved
    end

    describe "with rack_test driver" do
      before do
        allow(capybara_mock).to receive(:current_driver).and_return(:rack_test)
      end

      it 'indicates that a screenshot could not be saved' do
        saver.save
        expect(saver).to_not be_screenshot_saved
      end
    end

    describe "with mechanize driver" do
      before do
        allow(capybara_mock).to receive(:current_driver).and_return(:mechanize)
      end

      it 'indicates that a screenshot could not be saved' do
        saver.save
        expect(saver).to_not be_screenshot_saved
      end
    end
  end
end
