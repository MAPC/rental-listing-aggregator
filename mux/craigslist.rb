module Craigslist
  @@source = Source.find_by title: 'Craigslist'
  @@base_url = ENV['CRAIGSLIST_URL']

  @results_count = 0
  def self.crawl
    uri = URI(@@base_url + '/jsonsearch/apa/')
    res = Net::HTTP.get_response(uri)
    results = JSON.parse(assert_successful_response(res)).first
    survey  = Survey.create
    # Iterating

    results.each do |r|
      create_listing_from_result(r, survey) unless r.has_key?('GeoCluster')
      break if ENV['MAX_RESULTS'] && @results_count > ENV['MAX_RESULTS'].to_i
      fetch_nested(r.fetch('url'), survey) if r.has_key?('GeoCluster')
    end
  end

  def self.fetch_nested(geocluster, survey)
    return if ENV['MAX_RESULTS'] && @results_count > ENV['MAX_RESULTS'].to_i
    sleep(5)
    geocluster_url = @@base_url + geocluster
    uri = URI(geocluster_url)
    res = Net::HTTP.get_response(uri)
    results = JSON.parse( assert_successful_response (res) ).first

    results.each do |r|
      create_listing_from_result(r, survey) unless r.has_key?('GeoCluster')
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
    l = Listing.new location: location,
                ask: r.fetch('Ask') { :default } ,
                bedrooms: r['Bedrooms'],
                title: r['PostingTitle'],
                posting_date: date,
                survey: survey,
                source: @@source,
                payload: r.to_json,
                uid: r['PostingURL']

    if l.save
      @results_count += 1
      print 'Cragislist Result ' + @results_count.to_s + ': ' + l.title + "\n"
    else
      print 'FAILURE on Craigslist: ' + l.title + "\n"
    end
  end

end
