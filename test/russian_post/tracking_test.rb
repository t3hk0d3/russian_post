# encoding: UTF-8

require 'test_helper'

module RussianPost

  class TrackingTest < Test::Unit::TestCase

    def test_tracking 
      expected = 
      {
        :type => "Приём",
        :date => Time.parse("2012-10-17 01:44:00 +0400"),
        :zip_code => nil, 
        :location => "Китай 200949", 
        :message => nil, :weight => nil, 
        :declared_cost => nil, :delivery_cash => nil, 
        :destination_zip_code => nil, 
        :destination_location => nil
      }

      VCR.use_cassette('post_tracking') do
        tracking = RussianPost::Tracking.new('RA287813139CN').track

        assert_equal expected, tracking.first
      end
    end
  end
end