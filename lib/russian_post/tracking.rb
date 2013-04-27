require 'mechanize'

require 'time'

module RussianPost

  class Tracking

    attr_reader :barcode, :agent

    TRACKING_PAGE = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'
    COLUMNS = [:type, :date, :zip_code, :location, :message, :weight, :declared_cost,
      :delivery_cash, :destination_zip_code, :destination_location]
    
    def initialize(tracking_code)
      @barcode = tracking_code.strip.upcase
      @agent   = Mechanize.new
    end

    def track
      initial_page = fetch_initial_page
      tracking_page = fetch_tracking_data(initial_page)
      parse_tracking_table(tracking_table(tracking_page))
    end

    private

    def solve_captcha(page)
      RussianPost::Captcha.for_url(get_captcha_url(page)).text
    end

    def get_captcha_url(page)
      page.images.last.src
    end

    def tracking_table(page)
      table = page.search(".pagetext tbody tr")
      table ? table : raise("No tracking table found")
    end

    def parse_tracking_table(table)
      table.map { |e| parse_row(e) }
    end

    def parse_row(row)
      data = get_row_data(row)
      data[1] = Time.parse("#{data[1]} +04:00")

      Hash[COLUMNS.zip(data)]
    end

    def get_row_data(row)
      row.css('td').map { |td| td.text unless ['-', ''].include?(td.text) }
    end

    def fetch_initial_page
      page = agent.get(TRACKING_PAGE)
      page.form.has_field?("key") ? page.form.submit : page # bypass security

      # I just couldn't reproduce this behavior in 500+ requests. Maybe
      # it's more of an exception?
      # -- @artemshitov
      # elsif page.body.include?("window.location.replace(window.location.toString())")
      #   page = fetch_initial_page
      # end
      # page
    end

    def fetch_tracking_data(page)
      page.form.set_fields(
        'BarCode'            => barcode,
        'InputedCaptchaCode' => solve_captcha(page),
        'searchsign'         => '1')
      page.form.submit
    end
  end
end
