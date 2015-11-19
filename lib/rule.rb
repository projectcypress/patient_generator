class Rule

  def initialize(data_criteria, criteria_list)
    @dataCriteria = data_criteria
    @sourceDataCriteria = data_criteria[:source_data_criteria]
    @criteriaType = data_criteria[:type]
    @temporalReferences = data_criteria[:temporal_references]
    @criteriaList = criteria_list
  end

end