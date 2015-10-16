class MongoWrapper

  def initialize(measure_as_hash)
  	@measure = measure_as_hash
  end

  def population_ids
  	@measure['population_ids']
  end

  def hqmf_document
    @measure['hqmf_document']
  end

end