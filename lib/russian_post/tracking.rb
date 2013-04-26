require 'excon'
require 'nokogiri'

require 'time'
require 'cgi'

module RussianPost

  class Tracking

    attr_reader :barcode, :current_page, :current_html

    TRACKING_PAGE = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'
    ACTION_URL = 'http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo'

    def initialize(tracking_code)
      @barcode = tracking_code.strip.upcase
    end

    def track
      fetch_initial_page!

      response = request_tracking_data(prepare_params, prepare_cookies)
      body = Nokogiri::HTML::Document.parse(response.body)
      
      if body.css("table.pagetext")
        parse_tracking_table(body)
      else
        raise "No tracks table in response"
      end
    end

    private

    def solve_captcha
      captcha = RussianPost::Captcha.for_url(parse_captcha_url)
      raise "Unable to recognize captcha" unless captcha.valid?
      captcha.text
    end

    def parse_request_form
      current_html.css("input").reduce({}) do |acc, result|
        acc.merge Hash[result.attr("name"), result.attr("value")]
      end
    end

    def parse_captcha_url
      current_html.css("#captchaImage").attr("src") or raise "Unable to extract captcha image url"
    end

    def parse_tracking_table(body)
      columns = [:type, :date, :zip_code, :location, :message, :weight,
        :declared_cost, :delivery_cash, :destination_zip_code, :destination_location]

      body.css('table.pagetext tbody tr').map do |row|
        data = row.css('td').map { |td| td.text unless ['-', ''].include?(td.text) }

        data[1] = Time.parse("#{data[1]} +04:00")
        Hash[columns.zip(data)]
      end
    end

    def request_tracking_data(params, cookies)
      request_data = encode_params(params)

      Excon.post(ACTION_URL, 
        :headers => {'Cookie' => cookies,
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22',
          'Referer' => 'http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo',
          'Origin' => 'http://www.russianpost.ru',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Content-Length' => request_data.size },
        :body => request_data)
    end

    def prepare_params
      parse_request_form.merge(
        'BarCode'            => barcode,
        'InputedCaptchaCode' => solve_captcha,
        'searchsign'         => '1' # strictly required
      )
    end

    def prepare_cookies
      cookies = Hash[current_page.headers['Set-Cookie'].scan(/([^\=\;]+)=([^\;]+)[^\,]*,*/).map { |name, value| [name.strip, value.strip] }]
      cookies.delete("path")
      cookies.map { |name, value| "#{name}=#{value}"}.join("; ")
    end

    def encode_params(params)
      params.map do |name, value|
        "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}"
      end.join('&')
    end

    def fetch_initial_page!
      response = Excon.get(TRACKING_PAGE)
      if response.body =~ /<input id=\"key\" name=\"key\" value=\"([0-9]+)\"\/>/ # tough security huh
        response = Excon.post(TRACKING_PAGE, body: "key=#{$1}")
      end

      if response.body.include?("window.location.replace(window.location.toString())") # hehe
<<<<<<< HEAD
<<<<<<< HEAD
        response = fetch(url)
=======
        puts "foo"
        response = fetch_initial_page!(url)
>>>>>>> Saved initial page as an instance state
=======
        fetch_initial_page!
>>>>>>> Extracted params preparation to a separate method and improved initial page fetching a bit
      end

      @current_page = response
      @current_html = Nokogiri::HTML(response.body)
    end

  end

end
