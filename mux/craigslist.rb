require 'faraday'

module Craigslist
  @@source = Source.find_by title: 'Craigslist'
  @@base_url = ENV['CRAIGSLIST_URL']

  @results_count = 0

  @new_results = 0
  @changed_results = 0

  def self.crawl
    uri = URI(@@base_url + '/jsonsearch/apa?map=1')

    begin
      res = Net::HTTP.get_response(uri)
    rescue StandardError => e
      STDERR.puts 'Could not connect to Craigslist. Aborting Craigslist scrape...'
      sleep(1)
      return
    end

    results = JSON.parse(assert_successful_response(res)).first
    survey  = Survey.create

    # Iterating
    results.each do |r|
      begin
        create_listing_from_result(r, survey) unless r.has_key?('GeoCluster')
      rescue StandardError => e
        puts 'ERROR: ' + e.message.to_s
      end

      break if ENV['MAX_RESULTS'] && @results_count > ENV['MAX_RESULTS'].to_i
      fetch_nested(r.fetch('url'), survey) if r.has_key?('GeoCluster')
    end

    print sprintf("Craigslist: %d results, %d new, %d changed\n", @results_count, @new_results, @changed_results)

    conn = Faraday.new(:url => 'https://hooks.slack.com')
    conn.post do |req|
      req.url '/services/T031NFK37/BQ4TX0ZK8/UNGggcaanV8CnPlAIKEjSA1b'
      req.headers['Content-Type'] = 'application/json'
      req.body = "{\"text\":\"Craigslist: #{@results_count} results, #{@new_results} new, #{@changed_results} changed\"}"
    end

    return @results_count
  end

  def self.fetch_nested(geocluster, survey)
    return if ENV['MAX_RESULTS'] && @results_count > ENV['MAX_RESULTS'].to_i
    sleep(5)
    geocluster_url = @@base_url + geocluster
    uri = URI(geocluster_url)

    begin
      res = Net::HTTP.get_response(uri)
    rescue StandardError => e
      STDERR.puts 'ERROR: ' + e.message.to_s
      STDERR.puts "Could not connect to Craiglist at #{geocluster_url}\n Aborting..."
      sleep(1)
      return
    end

    results = JSON.parse( assert_successful_response (res) ).first

    results.each do |r|
      begin
        create_listing_from_result(r, survey) unless r.has_key?('GeoCluster')
      rescue StandardError => e
        STDERR.puts 'ERROR: ' + e.message.to_s
      end

      fetch_nested(r.fetch('url'), survey) if r.has_key?('GeoCluster')
    end
  end

  def self.factory
    RGeo::Geographic.spherical_factory(:srid => 4326)
  end

  def self.assert_successful_response(response)
    return unless response.code.to_s == '200'
    response.body
  end

  def self.create_listing_from_result(result, survey)
    r = result
    location = factory.point r['Longitude'], r['Latitude']
    date = DateTime.strptime r['PostedDate'].to_s, '%s'

    # Creating a listing
    #l = Listing.find_or_initialize_by(uid: r['PostingURL'])
    l = Listing.create
    l.uid = result['PostingURL']

    # Track which fields are changing so that we have a sense of hwo to logically do deduplication
    fields_changed = []

    #unless l.new_record?
    #  fields_changed << 'ask' unless l.ask == r.fetch('Ask') { :default }
    #  fields_changed << 'title' unless l.title == r['PostingTitle']
    #  fields_changed << 'location' unless l.location.x == location.x && l.location.y == location.y
    #end

    l.location = location
    begin
      l.ask = r.fetch('price')
    rescue KeyError => e
      STDERR.puts 'ERROR: ' + e.message.to_s
    end
    begin
      l.bedrooms = r.fetch('bedrooms')
    rescue KeyError => e
      STDERR.puts 'ERROR: ' + e.message.to_s
    end
    l.title = r['PostingTitle']
    l.posting_date = date
    l.survey = survey
    l.source = @@source
    l.payload = r
    l.last_seen = DateTime.now

    @results_count += 1

    if l.save
      @new_results += 1 if fields_changed.count.zero?
      if fields_changed.count > 0
        @changed_results += 1
        puts "Changed fields: " + fields_changed.join(' ') + "\n"
      end
      puts 'New/changed Cragislist result ' + @results_count.to_s + ': ' + l.title + "\n" if ENV['RACK_ENV'] == 'development'
    else
      puts 'FAILURE on Craigslist: ' + l.title + "\n"
    end
  end

end
