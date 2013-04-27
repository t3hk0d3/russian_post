require 'excon'
require 'chunky_png'

module RussianPost

  class Captcha

    require 'russian_post/captcha/patterns'

    attr_reader :patterns

    class << self

      def for_url(url, patterns = nil)
        RussianPost::Captcha.new(url, nil, patterns)
      end

      def for_data(data, patterns = nil)
        RussianPost::Captcha.new(nil, data, patterns)
      end

    end

    def image
      @data ||= fetch_image
    end

    def text
      @recognized_text ||= prepare_text(recognize)
    end

    def valid?
      text.size == 5
    end

    def recognize
      @recognize ||= recognize!
    end

    def recognize!
      captcha_image = grayscale(image)

      results = {}

      for x in 0..captcha_image.width - 2
        for y in 0..captcha_image.height - 2
          result = patterns.find(captcha_image, x, y)

          results[x] = result if result
        end
      end

      Hash[results.sort].values
    end

    private 

    def initialize(url = nil, data = nil, patterns = nil) # private constructor
      @url = url
      @data = ChunkyPNG::Image.from_blob(data) if data
      @patterns ||= RussianPost::Captcha::Patterns.built_in 
    end

    def prepare_text(results)
      captcha_text = results.map(&:character).join('')
      captcha_text.size == 5 ? captcha_text : raise("Unable to recognize captcha")
    end

    def grayscale(captcha_image)
      captcha_image.pixels.map! { |color| color = ChunkyPNG::Color.grayscale_teint(color); color = (color >= 255) ? 255 : 0 ; color }

      captcha_image
    end

    def fetch_image
      raise "URL not specified" unless @url

      data = Excon.get(@url).body

      unless data.start_with?("\x89PNG".force_encoding("ASCII-8BIT")) # not png header
        if data =~ /<input id=\"key\" name=\"key\" value=\"([0-9]+)\"\/>/ # tough security huh
          data = Excon.post(@url, body: "key=#{$1}").body
        end

        if data =~ /Object moved/ # faulty captcha
          raise "Russian Post captcha service error"
        end

        if data.include?("window.location.replace(window.location.toString())")
          return fetch_image # start from beginning
        end
      end

      ChunkyPNG::Image.from_blob(data)
    end

  end

end
