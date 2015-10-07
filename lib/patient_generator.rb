class Generator

  def initialize(measure, populations=["IPP"])
    @measure = measure
    @populations
  end

  def generate_criteria_path
    @criteria_list = {}
    @populations.each do |pop|
      population = get_population_criteria(pop)
      population.precondtions.each do |pre|
        handle_precondition(pre)
      end
    end
  end

  def handle_precondition
    # is it a grouping condtion
    if pre["negation"]
      return nil
    elsif pre["reference"]
      handle_data_criteria(pre["reference"])
    elsif pre["conjunction_code"] == "allTrue"
      handle_and_criteria(pre)
    elsif pre["conjunction_code"] == "atLeastOneTrue"
      handle_or_criteria(pre)
    end
  end

  def handle_or_critieria
    len = precondition["preconditions"].length 
    pre = precondition["preconditions"][rand(len)]
    handle_precondition(pre)
  end

  def handle_and_critieria(precondition)
    precondition["preconditions"].each do |pre|
      handle_precondition(pre)
    end
  end

  def handle_data_criteria(id, temporal_references=[])
    crit = get_data_criteria(id)
    if crit["type"] == "derived"
      handle_grouping_critiera(crit,temporal_references)
    elsif crit["type"] == "characteristic"
      handel_patient_characteristic(crit,temporal_references)
    else
      handle_single_criteria(crit,temporal_references)
    end
  end
  
  def handle_patient_characteristic(crit, temporal_references = [])

  end

  def handle_single_criteria(crit, temporal_references = [])

  end
  
  def handle_grouping_critiera(crit,temporal_references)
    if crit["definition"] == "satisfies_all"
      handle_satisfies_all(crit,temporal_references)
    elsif crit["definition"] == "satisfies_any"
      handle_satisfies_any(crit,temporal_references)
    elsif crit["derivation_operator"] == "UNION"
      handle_union_criteria(crit,temporal_references)
    elsif crit["derivation_operator"] == "INTERSECTION"
      handle_intersection_critieria(crit,temporal_references)
    end
  end

  def handle_union_criteria(crit, temporal_references = [])
    tr = crit["temporal_references"] || []
    len = crit["children_criteria"].length
    handle_data_criteria(crit["children_criteria"][rand[len]], tr)
  end

  def handle_intersection_critieria(crit, temporal_references = [])
    crit["children_criteria"].each do |ch|
      tr = crit["temporal_references"] || []
      handle_data_criteria(ch,tr)
    end
  end

  def handle_satisfies_all(crit, temporal_references = [])
  end

  def handle_satisfies_any(crit, temporal_references = [])

  end

  def get_population_criteria(population)
    pop_hqmf_id = @measure.population_ids['population']
    pop_id, pop_criteria = @measure.hqmf_document['population_criteria'].find do |population_id, population_criteria|
      population_criteria['hqmf_id'] == pop_hqmf_id
    end
    pop_id
  end

  def get_data_criteria(id)
    @measure.hqmf_document["data_criteria"][id]
  end

end
