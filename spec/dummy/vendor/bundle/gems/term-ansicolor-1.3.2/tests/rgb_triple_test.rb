require 'test_helper'

class RgbTripleTest < Test::Unit::TestCase
  include Term::ANSIColor

  def test_rgb_cast
    rgb = RGBTriple.new(128, 0, 255)
    assert_equal '#8000ff', RGBTriple[ rgb ].html
    assert_equal '#8000ff', RGBTriple[ [ 128, 0, 255 ] ].html
    assert_equal '#8000ff', RGBTriple[ :red => 128, :green => 0, :blue => 255 ].html
    assert_raises ArgumentError do
      RGBTriple[ nil ]
    end
  end

  def test_rgb_to_a
    rgb = RGBTriple.new(128, 0, 255)
    assert_equal [ 128, 0, 255 ], rgb.to_a
  end

  def test_rgb_distance
    rgb1 = RGBTriple.new(128, 0, 255)
    rgb2 = RGBTriple.new(128, 200, 64)
    assert_in_delta 0.0, rgb1.distance_to(rgb1), 1e-3
    assert_in_delta 255, RGBTriple.new(0, 0, 0).distance_to(RGBTriple.new(255, 255, 255)), 1e-3
    assert_in_delta 209.935, rgb1.distance_to(rgb2), 1e-3
  end

  def test_rgb_gray
    rgb1 = RGBTriple.new(0, 0, 0)
    assert_equal false, rgb1.gray?
    rgb2 = RGBTriple.new(255, 255, 255)
    assert_equal false, rgb2.gray?
    rgb3 = RGBTriple.new(12, 23, 34)
    assert_equal false, rgb3.gray?
    rgb4 = RGBTriple.new(127, 127, 127)
    assert_equal true, rgb4.gray?
  end

  def test_gradient
    rgb1 = RGBTriple.new(0, 0, 0)
    rgb2 = RGBTriple.new(255, 255, 255)
    g0 = rgb1.gradient_to(rgb2, :steps => 2)
    assert_equal 2, g0.size
    assert_equal rgb1, g0[0]
    assert_equal rgb2, g0[1]
    g1 = rgb1.gradient_to(rgb2, :steps => 3)
    assert_equal 3, g1.size
    assert_equal rgb1, g1[0]
    assert_equal 127, g1[1].red
    assert_equal 127, g1[1].green
    assert_equal 127, g1[1].blue
    assert_equal rgb2, g1[2]
    g2 = rgb1.gradient_to(rgb2, :steps => 6)
    assert_equal 6, g2.size
    assert_equal rgb1, g2[0]
    assert_equal 51, g2[1].red
    assert_equal 51, g2[1].green
    assert_equal 51, g2[1].blue
    assert_equal 102, g2[2].red
    assert_equal 102, g2[2].green
    assert_equal 102, g2[2].blue
    assert_equal 153, g2[3].red
    assert_equal 153, g2[3].green
    assert_equal 153, g2[3].blue
    assert_equal 204, g2[4].red
    assert_equal 204, g2[4].green
    assert_equal 204, g2[4].blue
    assert_equal rgb2, g2[5]
  end
end
