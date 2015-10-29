module Craigslist
  @queue = :default

  def self.perform
    sleep(5)
    uri = URI("http://boston.craigslist.org/jsonsearch/aap/")
    res = Net::HTTP.get_response(uri)

    factory = RGeo::Geographic.spherical_factory(:srid => 4326)

    survey = Survey.create()

    if res.code == "200"
      result = JSON.parse(res.body)
      result[0].each do |r|
        puts r
      end
    end
  end
end
