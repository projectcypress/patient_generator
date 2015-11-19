class ProcedureRule < Rule
   
  def execute(birthdate_value)
    reference = @criteriaList[@sourceDataCriteria]
    @measurePeriod = 31540000
    @measurePeriodStartDate = Time.now - @measurePeriod*2
  end

  def handle_procedure_criteria(crit)
    procedure = Procedure.new()
    crit['temporal_references'].each do |ref|
      if ref['type'] == "DURING"
        reference = get_data_criteria(ref['reference'])
        criteria = @criteria_list[:single_criteria].select{|crit| crit['source_data_criteria'] == ref['reference']}[0]
        type = criteria['type'].to_sym
        time = @fields[type].select{|crit| crit['codes']['SNOMED-CT'] == criteria['code_list_id']}[0].time
        procedure.time = time
      end
    end
    procedure
  end

end