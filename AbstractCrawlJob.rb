class AbstractCrawlJob

  def url
    raise NotImplementedError
  end

  def get_records_from_response(response)
    raise NotImplementedError
  end

  def skip_if(record)
    raise NotImplementedError
  end

  def create_listing_from_result(result, options={})
    raise NotImplementedError
  end

  private


end