require 'test_helper'

class RussianPost::Captcha::PatternsTest < Test::Unit::TestCase

  def setup
    @image = load_captcha_image

    @patterns = RussianPost::Captcha::Patterns.built_in # @FIXME use mock patterns instead
    
  end

  def test_builtin_patterns 
    assert @patterns.patterns.size > 0
  end

  def test_find
    assert_equal '4', @patterns.find(@image, 4, 3).character
  end

end