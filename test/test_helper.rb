$:.unshift File.expand_path("../lib/russian_post/", File.dirname(__FILE__))

require 'test/unit'
require 'webmock/test_unit'

require 'russian_post'

class Test::Unit::TestCase

  def load_captcha_file
    File.open('test/fixtures/captcha.png', 'rb') { |f| f.read }
  end


  def load_captcha_image
      image = ChunkyPNG::Image.from_file('test/fixtures/captcha.png')
      image.pixels.map! { |color| color = ChunkyPNG::Color.grayscale_teint(color); color = (color >= 255) ? 255 : 0 ; color }

      image
  end

end

