module Padmapper
  @stash = []
  @stacks = 0
  @current_survey
  @source = Source.find(2)

  def self.crawl
    munis = Municipality.pluck(:geom)
    region = munis.inject &:union
    geoms = [region]
    # geoms = [Municipality.find(180).geom]
    bboxs = geoms.map { |x| create_bbox(x) }
    
    # source = Source.find(2)
    @current_survey = Survey.create
    recursive_subdivide(bboxs)
    crawl_stash
  end

  def self.crawl_stash
    unique = @stash.uniq
    unique.each_slice(50) { |r|  
      sleep(3)
      ids = r.join(",")
      res = Net::HTTP.post_form(URI(Padmapper.listings_query_string), 'ids' => ids)
      JSON.parse(res.body).each do |r|
        create_listing_from_result(r)
      end
    }
  end

  def self.assert_batch_has_unique(array)
    ids = array.map { |x| x["id"] }
    ids.any? { |id| !@stash.include? id }
  end

  def self.recursive_subdivide(bboxs)
    bboxs.each do |r|
      sleep(3)
      uri = URI( query_string ( get_coords (r) )) 
      res = Net::HTTP.get_response(uri)

      results = JSON.parse( assert_successful_response (res) )
      puts "uri: #{uri}"
      puts "results count: #{results.count}"
      puts "stash count: #{@stash.count}"
      puts "stash contains unique ids: #{@stash.uniq.count}"
      puts "stacks: #{@stacks}"
      if assert_batch_has_unique(results) && results.count > 0
        @stacks+=1
        @stash.concat results.map { |x| x["id"] }
        recursive_subdivide(r.subdivide)
      end
    end
  end

  def self.create_listing_from_result(result)
    r = result
    location = factory.point r["lng"], r["lat"]
    date = DateTime.strptime r["date"].to_s, "%s"

    # Creating a listing
    l = Listing.new location: location,
                ask: r.fetch("price") { :default } ,
                bedrooms: r["beds"],
                title: r["description"],
                posting_date: date,
                survey: @current_survey,
                source: @source

    if l.save
      # success message
    else
      # error message
    end
  end

  def self.get_coords(rgeo_bbox)
    { max_x: rgeo_bbox.max_x, 
      max_y: rgeo_bbox.max_y, 
      min_x: rgeo_bbox.min_x, 
      min_y: rgeo_bbox.min_y }
  end

  def self.assert_successful_response(response)
    return unless response.code.to_s == "200"
    response.body
  end

  def self.create_bbox(geom)
    RGeo::Cartesian::BoundingBox.create_from_geometry(geom)
  end

  def self.factory
    RGeo::Geographic.spherical_factory(:srid => 4326)
  end

  def self.listings_query_string
    "http://www.padmapper.com/pullListingsForCache.php"
  end

  def self.query_string(coords)
    "http://www.padmapper.com/reloadMarkersJSON.php?eastLong=#{coords[:max_x]}&northLat=#{coords[:max_y]}&westLong=#{coords[:min_x]}&southLat=#{coords[:min_y]}&cities=false&limit=3150&minRent=0&maxRent=6000&searchTerms=Words+Required+In+Listing&maxPricePerBedroom=6000&minBR=0&maxBR=10&minBA=1&maxAge=7&imagesOnly=false&phoneReq=false&cats=false&dogs=false&noFee=false&showSubs=true&showNonSubs=true&showRooms=true&showVac=false&userId=-1&pl=true&aptsrch=true&forrent=true&hmst=true&kijiji=true&airbnb=false&ood=true&zoom=12&favsOnly=false&onlyHQ=true&showHidden=false&am=false&workplaceLat=0&workplaceLong=0&maxTime=0"
  end
end