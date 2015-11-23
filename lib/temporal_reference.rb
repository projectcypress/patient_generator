class TemporalReference

  def initialize(temporal_object, execution_context)
    @executionContext = execution_context
    @type = temporal_object[:type]
    @reference = temporal_object[:reference]
    generate_bounds()   
    binding.pry
  end

  def within_date_value(date_value)
    if @type == 'SBS'
      if @lowerBound['inclusive?']
        if date_value <= @lowerBound['value']
  	      return date_value
        else
          # lowest_bound = 520.weeks.since(Time.at(@lowerBound['value']))
          return generate_new_date_value('hi', 'bye')
        end
      else
        if date_value < @lowerBound['value']
          return date_value
        else
          return generate_new_date_value('hi', 'bye')
        end
      end
  	elsif @type == 'DURING'
      if @lowerBound['inclusive?']

    else 
      return 0
    end


    end  
  end

  def generate_new_date_value(lower_bound, upper_bound)
    # return Time.at(rand(lower_bound..upper_bound))
    return 1
  end

  def generate_bounds
    reference_object = (@reference == "MeasurePeriod") ? @executionContext.get_measure_period() : TemporalReference.new(@executionContext.get_criteria_list().select{|crit| crit['source_data_criteria'] == @reference }[0]['temopral_references'][0], @executionContext)
    binding.pry
    @lowerBound = reference_object[:low] ? 
    @upperBound = reference_object[:high] ? 
  end

  def get_data_criteria(id)
    @measure.hqmf_document["data_criteria"][id]
  end

end