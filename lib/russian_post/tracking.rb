require 'excon'
require 'nokogiri'

require 'time'
require 'cgi'

module RussianPost

  class Tracking

    attr_reader :barcode

    TRACKING_PAGE = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'

    def initialize(tracking_code)
      @barcode = tracking_code.strip.upcase
    end

    def track
      response = fetch(TRACKING_PAGE)
      body = Nokogiri::HTML::Document.parse(response.body)

      tracking_params = parse_request_form(body)

      action_path = parse_action_path(body) or raise "Unable to extract form path"

      tracking_params['BarCode'] = barcode
      tracking_params['InputedCaptchaCode'] = solve_captcha(body)
      tracking_params['searchsign'] = '1' # strictly required

      response = request_tracking_data(tracking_params, prepare_cookies(response), action_path)

      if response.body =~ /<table class="pagetext">(.+)<\/table>/
        parse_tracking_table(response.body)
      else
        raise "No tracks table in response"
      end
    end

    private

    def solve_captcha(body)
      captcha = RussianPost::Captcha.for_url(parse_captcha_url(body))
      raise "Unable to recognize captcha" unless captcha.valid?
      captcha.text
    end

    def parse_request_form(body)
      body.css("input").reduce({}) do |acc, result|
        acc.merge Hash[result.attr("name"), result.attr("value")]
      end
    end

    def parse_action_path(body)
      body.css("form").attr("action")
    end

    def parse_captcha_url(body)
      body.css("#captchaImage").attr("src") or raise "Unable to extract captcha image url"
    end

    def parse_tracking_table(body)
      doc = Nokogiri::HTML::Document.parse(body)

      columns = [:type, :date, :zip_code, :location, :message, :weight,
        :declared_cost, :delivery_cash, :destination_zip_code, :destination_location]

      doc.css('table.pagetext tbody tr').map do |row|
        data = row.css('td').map { |td| td.text unless ['-', ''].include?(td.text) }

        data[1] = Time.parse("#{data[1]} +04:00")
        Hash[columns.zip(data)]
      end
    end

    def request_tracking_data(params, cookies, action_path)
      request_data = encode_params(params)

      Excon.post('http://www.russianpost.ru' + action_path, 
        :headers => {'Cookie' => cookies,
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22',
          'Referer' => 'http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo',
          'Origin' => 'http://www.russianpost.ru',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Content-Length' => request_data.size },
        :body => request_data)
    end

    def prepare_cookies(response)
      cookies = Hash[response.headers['Set-Cookie'].scan(/([^\=\;]+)=([^\;]+)[^\,]*,*/).map { |name, value| [name.strip, value.strip] }]
      cookies.delete("path")
      cookies.map { |name, value| "#{name}=#{value}"}.join("; ")
    end

    def encode_params(params)
      params.map do |name, value|
        "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}"
      end.join('&')
    end

    def fetch(url)
      response = Excon.get(url)
      if response.body =~ /<input id=\"key\" name=\"key\" value=\"([0-9]+)\"\/>/ # tough security huh
        response = Excon.post(url, body: "key=#{$1}")
      end

      if response.body.include?("window.location.replace(window.location.toString())") # hehe
        response = fetch(url)
      end

      response
    end

  end

end
