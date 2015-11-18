module Craigslist # < AbstractCrawlJob
  @source = Source.find(1)

  def self.crawl
    uri = URI("http://boston.craigslist.org/jsonsearch/aap/")
    res = Net::HTTP.get_response(uri)

    results = JSON.parse( assert_successful_response (res) ).first
    survey  = Survey.create
    # Iterating

    results.each do |r|
      create_listing_from_result(r, survey) if !r.has_key?("GeoCluster")
      fetch_nested(r.fetch("url"), survey) if r.has_key?("GeoCluster")
    end
  end

  # def self.fetch_nested(geocluster, survey)
  #   sleep(5)
  #   geocluster_url = "http://boston.craigslist.org" + geocluster
  #   uri = URI(geocluster_url)
  #   res = Net::HTTP.get_response(uri)
  #   results = JSON.parse( assert_successful_response (res) ).first

  #   results.each do |r|
  #     create_listing_from_result(r, survey) if !r.has_key?("GeoCluster")
  #   end
  # end

  # def self.factory
  #   RGeo::Geographic.spherical_factory(:srid => 4326)
  # end

  # def self.assert_successful_response(response)
  #   return unless response.code.to_s == "200"
  #   response.body
  # end

  # def self.create_listing_from_result(result, survey)
  #   r = result
  #   location = factory.point r["Longitude"], r["Latitude"]
  #   date = DateTime.strptime r["PostedDate"], "%s"

  #   # Creating a listing
  #   l = Listing.new location: location,
  #               ask: r.fetch("Ask") { :default } ,
  #               bedrooms: r["Bedrooms"],
  #               address: r.fetch("location"),
  #               title: r["PostingTitle"],
  #               posting_date: date,
  #               survey: survey,
  #               source: @source

  #   if l.save
  #     # success message
  #   else
  #     # error message
  #   end

  # end


end
