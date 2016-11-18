module Padmapper
  @@stash = []
  @@stacks = 0
  @@current_survey
  @@source = Source.find(2)
  @@csrftoken = nil
  @@zumpertoken = nil
  @@tokens = nil


  def self.crawl
    # munis = Municipality.pluck(:geom)
    # region = munis.inject &:union
    # geoms = [region]
    # # geoms = [Municipality.find(180).geom]
    # bboxs = geoms.map { |x| create_bbox(x) }
    
    # # source = Source.find(2)
    # @@current_survey = Survey.create
    # recursive_subdivide(bboxs)
    # crawl_stash
    get_tokens
    crawl_stash

  end

  def self.filters
    {bedrooms:nil,
      buildingIds:nil,
      cats:nil,
      dogs:nil,
      featuredLimit:3,
      keywords:nil,
      limit:20,
      listingIds:nil,
      matching:true,
      maxDays:nil,
      maxPrice:nil,
      maxPricePerBedroom:nil,
      maxLat:42.41002,
      minLat:42.16086,
      maxLng:-70.95639,
      minLng:-71.39481,
      minPrice:nil,
      noFees:nil,
      offset:0,
      sort:nil,
      url:nil,
      minBathrooms:nil,
      feeds:["-airbnb"]}
  end


  def self.get_tokens
    url = URI("https://www.padmapper.com/api/t/1/bundle")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["cache-control"] = 'no-cache'

    response = JSON.parse(http.request(request).read_body)

    @@csrftoken = response["csrf"]
    @@zumpertoken = response["xz_token"]
    @@tokens = { 'x-csrftoken' => @@csrftoken, 'x-zumper-xz-token' => @@zumpertoken }
  end

  def self.crawl_stash
    unique = @@stash.uniq
    unique.each_slice(50) { |r|  
      crawl_slice(r)
    }
  end

  def self.crawl_slice(slice)
    sleep(3)
    url = URI("https://www.padmapper.com/api/t/1/pages/listables")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["user-agent"] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36'
    request["x-csrftoken"] = @@csrftoken
    request["x-zumper-xz-token"] = @@zumpertoken
    request["content-type"] = 'application/json'
    request["cache-control"] = 'no-cache'
    request.body = hash.to_json

    response = http.request(request)
    puts response.read_body

    JSON.parse(res.body).each do |r|
      create_listing_from_result(r)
    end
  end

  def self.bundle 
    # include header codes required for successful API requests
    "https://www.padmapper.com/api/t/1/bundle"
  end

  def self.listables
    "https://www.padmapper.com/api/t/1/pages/listables"
  end

  # old

  # def self.assert_batch_has_unique(array)
  #   ids = array.map { |x| x["id"] }
  #   ids.any? { |id| !@@stash.include? id }
  # end

  # def self.recursive_subdivide(bboxs)
  #   bboxs.each do |r|
  #     sleep(2)
  #     uri = URI( query_string ( get_coords (r) )) 
  #     res = Net::HTTP.get_response(uri)

  #     results = JSON.parse( assert_successful_response (res) )
  #     if assert_batch_has_unique(results) && results.count > 0
  #       @@stacks+=1
  #       @@stash.concat results.map { |x| x["id"] }
  #       recursive_subdivide(r.subdivide)
  #     end
  #   end
  # end

  # def self.create_listing_from_result(result)
  #   r = result
  #   location = factory.point r["lng"], r["lat"]
  #   date = DateTime.strptime r["date"].to_s, "%s"

  #   # Creating a listing
  #   l = Listing.new location: location,
  #               ask: r.fetch("price") { :default } ,
  #               bedrooms: r["beds"],
  #               title: r["description"],
  #               posting_date: date,
  #               survey: @@current_survey,
  #               source: @@source,
  #               payload: r.to_json

  #   if l.save
  #     # success message
  #   else
  #     # error message
  #   end
  # end

  # def self.get_coords(rgeo_bbox)
  #   { max_x: rgeo_bbox.max_x, 
  #     max_y: rgeo_bbox.max_y, 
  #     min_x: rgeo_bbox.min_x, 
  #     min_y: rgeo_bbox.min_y }
  # end

  # def self.assert_successful_response(response)
  #   return unless response.code.to_s == "200"
  #   response.body
  # end

  # def self.create_bbox(geom)
  #   RGeo::Cartesian::BoundingBox.create_from_geometry(geom)
  # end

  # def self.factory
  #   RGeo::Geographic.spherical_factory(:srid => 4326)
  # end


  # def self.make_request(uri, headers, http_method, bodycontent)
  #   url = URI(uri)

  #   http = Net::HTTP.new(url.host, url.port)
  #   http.use_ssl = true
  #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  #   headers.merge!(@@tokens)
  #   headers['body' => bodycontent]

  #   if (http_method == "get")
  #     request = Net::HTTP::Get.new(url)
  #   else
  #     request = Net::HTTP::Post.new(url)
  #   end

  #   headers.each_pair do |key, value| 
  #     request[key] = value
  #   end
  #   # request.assign_attributes(headers)

  #   http.request(request, URI.encode_www_form(headers))
  # end


end
