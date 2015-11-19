class TemporalReference

  def initialize(temporal_object)
    @type = temporal_object[:type]
    @reference = temporal_object[:reference]    
  end

end