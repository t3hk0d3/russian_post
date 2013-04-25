require 'excon'
require 'nokogiri'

require 'time'
require 'cgi'

module RussianPost

  class Tracking

    TRACKING_PAGE = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'

    def initialize(tracking_code)
      @code = tracking_code.strip
    end

    def track
      # fetch form
      response = fetch(TRACKING_PAGE)

      tracking_form = response.body

      tracking_params = {}

      tracking_form.scan(/\<input ([^\>]+)\>/) do |result|
        param = Hash[result.first.scan(/(name|value)=(?:"|')([^\"\']+)(?:"|')/)]

        tracking_params[param['name']] = param['value']
      end

      action_path = if tracking_form =~ /\<form .* action=\"([^\"]+)\"/
        $1
      else
        raise "Unable to extract form path"
      end

      captcha_url = if tracking_form =~ /<img id='captchaImage' src='([^\']+)'/
        $1
      else
        raise "Unable to extract captcha image url"
      end

      captcha =  RussianPost::Captcha.for_url(captcha_url)

      raise "Unable to recognize captcha" unless captcha.valid?

      tracking_params['BarCode'] = @code
      tracking_params['InputedCaptchaCode'] = captcha.text
      tracking_params['searchsign'] = '1' 

      cookies = Hash[response.headers['Set-Cookie'].scan(/([^\=\;]+)=([^\;]+)[^\,]*,*/).map { |name, value| [name.strip, value.strip] }]
      cookies.delete("path")
      cookies = cookies.map { |name, value| "#{name}=#{value}"}.join("; ")

      request_data = encode_params(tracking_params)

      response = Excon.post('http://www.russianpost.ru' + action_path, 
        :headers => {'Cookie' => cookies,
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22',
          'Referer' => 'http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo',\
          'Origin' => 'http://www.russianpost.ru',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Content-Length' => request_data.size
        },
        :body => request_data)

      if response.body =~ /<table class="pagetext">(.+)<\/table>/
        doc = Nokogiri::HTML::Document.parse(response.body)

        columns = [:type, :date, :zip_code, :location, :message, :weight, :declared_cost, :delivery_cash, :destination_zip_code, :destination_location]

        rows = []
        doc.css('table.pagetext tr').each do |row|
          data = row.css('td').map(&:text).map { |text| !['-', ''].include?(text) ? text : nil }

          next if data.empty?

          hash = Hash[columns.zip(data)]
          hash[:date] = Time.parse("#{hash[:date]} +04:00")

          rows << hash
        end

        return rows
      else
        raise "No tracks table in response"
      end
    end

    private

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
        puts "foo"
        response = fetch(url)
      end

      response
    end

  end

end