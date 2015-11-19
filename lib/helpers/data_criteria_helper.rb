module DataCriteriaHelper

  require 'health-data-standards'

  def self.extract_data_criteria(measure, populations=["IPP", "NUMER"])
    @measure = measure
    @populations = populations
    generate_criteria_path()
    return get_criteria_list()
  end

  def self.generate_criteria_path
    @criteria_list = []
    @populations.each do |pop|
      population = get_population_criteria(pop)
      population['preconditions'].each do |pre|
        handle_precondition(pre)
      end
    end
  end

  def self.handle_precondition(pre)
    if pre["negation"]
      handle_negation_criteria(pre)
    elsif pre["reference"]
      handle_data_criteria(pre["reference"])
    elsif pre["conjunction_code"] == "allTrue"
      handle_and_criteria(pre)
    elsif pre["conjunction_code"] == "atLeastOneTrue"
      handle_or_criteria(pre)
    end
  end

########################## START: NEGATION/SINGLE/AND/OR ##########################
  def self.handle_negation_criteria(precondition)
    return nil
  end

  def self.handle_data_criteria(id, temporal_references=[])
    crit = get_data_criteria(id)
    if crit["type"] == "derived"
      handle_grouping_critiera(crit,temporal_references)
    else
      handle_single_criteria(crit,temporal_references)
    end
  end

  def self.handle_and_criteria(precondition)
    precondition["preconditions"].each do |pre|
      handle_precondition(pre)
    end
  end

  def self.handle_or_criteria(precondition)
    len = precondition["preconditions"].length 
    pre = precondition["preconditions"][rand(len)]
    handle_precondition(pre)
  end
########################## END: NEGATION/SINGLE/AND/OR ##########################


########################## START: SINGLE/GROUPING ##########################
  def self.handle_single_criteria(crit, temporal_references = [])
    @criteria_list.push(crit)
  end

  def self.handle_grouping_critiera(crit,temporal_references)
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
########################## END:  SINGLE/GROUPING ##########################

########################## START: ALL/ANY/UNION/INTERSECTION ##########################
  def self.handle_union_criteria(crit, temporal_references = [])
    tr = crit["temporal_references"] || []
    len = crit["children_criteria"].length
    handle_data_criteria(crit["children_criteria"][rand[len]], tr)
  end

  def self.handle_intersection_critieria(crit, temporal_references = [])
    crit["children_criteria"].each do |ch|
      tr = crit["temporal_references"] || []
      handle_data_criteria(ch,tr)
    end
  end

  def self.handle_satisfies_all(crit, temporal_references = [])
  end

  def self.handle_satisfies_any(crit, temporal_references = [])
  end
########################## END: ALL/ANY/UNION/INTERSECTION ##########################

########################## START: UTILITY FUNCTIONS ##########################
  def self.get_population_criteria(population)
    pop_hqmf_id = @measure.population_ids[population]
    pop_id, pop_criteria = @measure.hqmf_document['population_criteria'].find do |population_id, population_criteria|
      population_criteria['hqmf_id'] == pop_hqmf_id
    end
    pop_criteria
  end

  def self.get_data_criteria(id)
    @measure.hqmf_document["data_criteria"][id]
  end

    # data criteria has an oid on it for a value set 
  def self.get_criteria_list
    return @criteria_list
  end
########################## END: UTILITY FUNCTIONS ##########################

end
