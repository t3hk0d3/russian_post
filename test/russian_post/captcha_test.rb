require 'test_helper'

module RussianPost

  class CaptchaTest < Test::Unit::TestCase

    def setup 
      @url = 'http://www.russianpost.ru/CaptchaService/CaptchaImage.ashx?Id=361256433'
    end 

    def test_recognize 
      captcha = RussianPost::Captcha.for_data(load_captcha_file)

      assert_equal '49396', captcha.text
    end

    def test_fetch
      stub_get = stub_request(:get, @url).to_return(:body => load_captcha_file, :headers => { 'Content-Type' => 'image/png' })

      RussianPost::Captcha.for_url(@url).recognize!

      assert_requested(stub_get)
    end

    def test_cunning_fetch
      @tough_security = "<html><head></head><body onload=\"document.myform.submit();\"><form method=\"post\" name=\"myform\" style=\"visibility:hidden;\"><input id=\"key\" name=\"key\" value=\"117413\"/><input type=\"submit\"/></form></body></html>\r\n\r\n"

      stub_get = stub_request(:get, @url).to_return(:body => @tough_security, :headers => { 'Content-Type' => 'text/html' })
      stub_post = stub_request(:post, @url).with(:body => 'key=117413').to_return(:body => load_captcha_file, :headers => { 'Content-Type' => 'image/png' })

      RussianPost::Captcha.for_url(@url).recognize!

      assert_requested(stub_get)
      assert_requested(stub_post)

    end

  end

end