module Padmapper
  @@stash = []
  @@stacks = 0
  @@current_survey = Survey.create
  @@source = Source.find_by(title: 'Padmapper')
  @@csrftoken = nil
  @@zumpertoken = nil
  @@tokens = nil
  @results_count = 0
  @new_results = 0
  @changed_results = 0

  def self.crawl
    get_tokens

    bboxs = RGeo::Cartesian::BoundingBox.create_from_points(
        factory.point(ENV['PADMAPPER_MIN_LON'], ENV['PADMAPPER_MIN_LAT']),
        factory.point(ENV['PADMAPPER_MAX_LON'], ENV['PADMAPPER_MAX_LAT'])
    )

    recursive_subdivide([bboxs])
    print sprintf("Padmapper: %d results, %d new, %d changed\n", @results_count, @new_results, @changed_results)
  end

  def self.filters(bbox)
    {
      limit: 100,
      maxLat: bbox.max_y,
      minLat: bbox.min_y,
      maxLng: bbox.max_x,
      minLng: bbox.min_x,
      feeds: ['-airbnb']
    }
  end

  def self.get_tokens
    url = URI('https://www.padmapper.com/api/t/1/bundle')

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request['cache-control'] = 'no-cache'

    response = JSON.parse(http.request(request).read_body)
    @@csrftoken = response['csrf']
    @@zumpertoken = response['xz_token']

    { 'x-csrftoken' => @@csrftoken, 'x-zumper-xz-token' => @@zumpertoken }
  end

  def self.crawl_slice(filters)
    sleep(3)
    url = URI('https://www.padmapper.com/api/t/1/pins')

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36'
    request['x-csrftoken'] = @@csrftoken
    request['x-zumper-xz-token'] = @@zumpertoken
    request['content-type'] = 'application/json'
    request['cache-control'] = 'no-cache'
    request.body = filters.to_json

    http.request(request).body
  end

  def self.assert_batch_has_unique(array)
    ids = array.map { |x| x['listing_id'] }
    ids.any? { |id| !@@stash.include?(id) }
  end

  def self.recursive_subdivide(bboxs)
    bboxs.each do |box|
      break if ENV['MAX_RESULTS'] && @results_count > ENV['MAX_RESULTS'].to_i
      sleep(2)

      begin
        results = JSON.parse(crawl_slice(filters(box)))
        next unless assert_batch_has_unique(results) && results.count > 0
      rescue Exception => e
        Raven.capture_exception(e)

        puts 'Could not connect to Padmapper slice. Continuing...'
        next
      end

      @@stacks += 1
      @@stash.concat results.map { |x| x['listing_id'] }

      results.each do |result|
        begin
          create_listing_from_result(result)
        rescue Exception => e
          Raven.capture_exception(e)
          puts 'Could not create listing record from Padmapper result. Continuing...'
        end
      end

      recursive_subdivide(box.subdivide)
    end
  end

  def self.create_listing_from_result(result)
    location = factory.point(result['lng'], result['lat'])
    date = DateTime.strptime(result['listed_on'].to_s, '%s')
    avg_price = (result['min_price'] + result['max_price']) / 2

    # Creating a listing
    l = Listing.find_or_initialize_by(uid: result['listing_id'])
    return unless l.new_record?

    l.location = location
    l.ask = avg_price
    l.bedrooms = result['max_bedrooms']
    l.title = result['address']
    l.posting_date = date
    l.survey = @@current_survey
    l.source = @@source
    l.payload = result.to_json
    l.last_seen = DateTime.now

    @results_count += 1
    if l.save
      @new_results += 1
      print 'New Padmapper result ' + @results_count.to_s + ': ' + l.title + "\n" if ENV['RACK_ENV'] == 'development'
    else
      print 'FAILURE on Padmapper ' + @results_count.to_s + ': ' + l.title + "\n"
    end
  end

  def self.factory
    RGeo::Geographic.spherical_factory(:srid => 4326)
  end

end
