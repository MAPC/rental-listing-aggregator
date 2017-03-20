module Padmapper
  @@stash = []
  @@stacks = 0
  @@current_survey = Survey.create
  @@source = Source.find_by title: 'Padmapper'
  @@csrftoken = nil
  @@zumpertoken = nil
  @@tokens = nil

  def self.crawl
    get_tokens

    munis = Municipality.pluck(:geom)
    region = munis.inject &:union
    # geoms = munis
    # geoms = [Municipality.find(180).geom]
    # bboxs = munis.map {|x| create_bbox(x)}
    bboxs = create_bbox(region)

    recursive_subdivide([bboxs])
  end

  def self.filters(bbox)
    {
      limit:100,
      maxLat: bbox.max_y,
      minLat: bbox.min_y,
      maxLng: bbox.max_x,
      minLng: bbox.min_x,
      feeds:["-airbnb"]
    }
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

    { 'x-csrftoken' => @@csrftoken, 'x-zumper-xz-token' => @@zumpertoken }
  end

  # def self.crawl_stash
  #   unique = @@stash.uniq
  #   unique.each_slice(50) { |r|  
  #     crawl_slice(r)
  #   }
  # end

  def self.crawl_slice(filters)
    sleep(3)
    url = URI("https://www.padmapper.com/api/t/1/pins")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["user-agent"] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36'
    request["x-csrftoken"] = @@csrftoken
    request["x-zumper-xz-token"] = @@zumpertoken
    request["content-type"] = 'application/json'
    request["cache-control"] = 'no-cache'
    request.body = filters.to_json

    http.request(request).body
  end

  def self.bundle 
    # include header codes required for successful API requests
    "https://www.padmapper.com/api/t/1/bundle"
  end

  def self.listables
    "https://www.padmapper.com/api/t/1/pages/listables"
  end

  # old

  def self.assert_batch_has_unique(array)
    ids = array.map { |x| x["listing_id"] }
    ids.any? { |id| !@@stash.include? id }
  end

  def self.recursive_subdivide(bboxs)
    bboxs.each do |r|
      sleep(2)
      puts "iterating"

      results = JSON.parse( crawl_slice( filters( r ) ) )
      if assert_batch_has_unique(results) && results.count > 0
        @@stacks+=1
        @@stash.concat results.map { |x| x["listing_id"] }
        results.each do |r|
          create_listing_from_result(r)
        end
        recursive_subdivide(r.subdivide)
      end
    end
  end

  def self.create_listing_from_result(result)
    r = result
    location = factory.point r["lng"], r["lat"]
    date = DateTime.strptime r["listed_on"].to_s, "%s"
    price = (r["min_price"] + r["max_price"]) / 2  #average price
    # Creating a listing
    l = Listing.new location: location,
                ask: price,
                bedrooms: r["max_bedrooms"],
                title: r["address"],
                posting_date: date,
                survey: @@current_survey,
                source: @@source,
                payload: r.to_json

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
