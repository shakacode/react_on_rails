require_relative 'test_helper'
require_relative '../lib/jquery/assert_select'

class AssertSelectJQueryTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions
  attr_reader :response

  JAVASCRIPT_TEST_OUTPUT = <<-JS
    $("#card").show("blind", 1000);
    $("#id").html('<div><p>something</p></div>');
    jQuery("#id").replaceWith("<div><p>something</p></div>");
    $("<div><p>something</p></div>").appendTo("#id");
    jQuery("<div><p>something</p></div>").prependTo("#id");
    $('#id').remove();
    jQuery("#id").hide();
  JS

  setup do
    @response = OpenStruct.new(content_type: 'text/javascript', body: JAVASCRIPT_TEST_OUTPUT)
  end

  def test_target_as_receiver
    assert_nothing_raised do
      assert_select_jquery :show, :blind, '#card'
      assert_select_jquery :html, '#id' do
        assert_select 'p', 'something'
      end
      assert_select_jquery :replaceWith, '#id' do
        assert_select 'p', 'something'
      end
    end

    assert_raise Minitest::Assertion, "No JQuery call matches [:show, :some_wrong]" do
      assert_select_jquery :show, :some_wrong
    end
  end

  def test_target_as_argument
    assert_nothing_raised do
      assert_select_jquery :appendTo, '#id' do
        assert_select 'p', 'something'
      end
      assert_select_jquery :prependTo, '#id' do
        assert_select 'p', 'something'
      end
    end

    assert_raise Minitest::Assertion, 'No JQuery call matches [:prependTo, "#wrong_id"]' do
      assert_select_jquery :prependTo, '#wrong_id'
    end
  end

  def test_argumentless
    assert_nothing_raised do
      assert_select_jquery :remove
      assert_select_jquery :hide
    end

    assert_raise Minitest::Assertion, 'No JQuery call matches [:wrong_function]' do
      assert_select_jquery :wrong_function
    end
  end
end
