require 'json'
require 'faraday'
require_relative '../app'
require_relative '../mux/padmapper'

module PadmapperScraper
  RSpec.describe 'Padmapper API' do
    it 'gets results within Cambridge' do
      token_response = JSON.parse(Faraday.get('https://www.padmapper.com/api/t/1/bundle').body)
      request_headers = { 'Accept': '*/*',
                          'Accept-Language': 'en-us',
                          'Cache-Control': 'no-cache',
                          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15',
                          'X-Zumper-Xz-Token': token_response['xz_token'],
                          'X-Csrftoken': token_response['csrf'] }
      request_body = {  'external': true,
                        'longTerm': false,
                        'minPrice': 0,
                        'shortTerm': false,
                        'transits': {},
                        'minLat': 42.3920465,
                        'maxLat': 42.4033521,
                        'minLng': -71.150168,
                        'maxLng': -71.1288048,
                        'limit': 100,
                        'feeds': ['-airbnb'] }
      pins_response = JSON.parse(Faraday.post('https://www.padmapper.com/api/t/1/pins', request_body, request_headers).body)
      puts "\tLISTINGS COUNT: " + pins_response.count.to_s
      expect(pins_response.count).to be > 10, "Expected more than 10 results, got #{pins_response.count} results from Padmapper"
    end

    it 'fails without a Zumper Token' do
      request_body = {  "external": true,
                        "longTerm": false,
                        "minPrice": 0,
                        "shortTerm": false,
                        "transits": {},
                        "minLat": 42.3920465,
                        "maxLat": 42.4033521,
                        "minLng": -71.150168,
                        "maxLng": -71.1288048,
                        "limit": 100 }
      pins_response = Faraday.post('https://www.padmapper.com/api/t/1/pins', request_body)
      expect(pins_response.status).not_to be 200
    end

    it 'gets the same number of results as the crawler' do
      skip 'This is a long running task'
      token_response = JSON.parse(Faraday.get('https://www.padmapper.com/api/t/1/bundle').body)
      request_headers = { 'Accept': '*/*',
                          'Accept-Language': 'en-us',
                          'Cache-Control': 'no-cache',
                          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15',
                          'X-Zumper-Xz-Token': token_response['xz_token'],
                          'X-Csrftoken': token_response['csrf'] }
      request_body = {  'external': true,
                        'longTerm': false,
                        'minPrice': 0,
                        'shortTerm': false,
                        'transits': {},
                        'minLat': 42.3920465,
                        'maxLat': 42.4033521,
                        'minLng': -71.150168,
                        'maxLng': -71.1288048,
                        'limit': 100,
                        'feeds': ['-airbnb'] }
      pins_response = JSON.parse(Faraday.post('https://www.padmapper.com/api/t/1/pins', request_body, request_headers).body)

      padmapper_crawler_count = Padmapper.crawl

      expect(pins_response.count).to equal(padmapper_crawler_count)
    end
  end
end
