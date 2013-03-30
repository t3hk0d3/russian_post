require 'test_helper'

class RussianPost::Captcha::PatternTest < Test::Unit::TestCase

  def setup
    @image = load_captcha_image

    @points = [[5, 0], [6, 0], [7, 0], [8, 0], [10, 0], [4, 1], [10, 1], [10, 2], [10, 3], [5, 4], [10, 4], [1, 5], [5, 5], [10, 5],
    [5, 6], [10, 6], [0, 7], [5, 7], [0, 8], [3, 8], [4, 8], [0, 9], [11, 9], [11, 10], [0, 11], [1, 11], [2, 11], [3, 11], [5, 11],
    [5, 12], [10, 13], [5, 14], [6, 14], [7, 14], [8, 14], [9, 14]]

    @pattern = RussianPost::Captcha::Pattern.new(@points, '4')
  end

  def test_find_pattern 
    assert @pattern.match?(@image, 4, 3)
  end

end
