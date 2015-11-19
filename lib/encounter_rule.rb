class EncounterRule < Rule
   
  def execute(birthdate_value)
    reference = @criteriaList[@sourceDataCriteria]
    @measurePeriod = 31540000
    @measurePeriodStartDate = Time.now - @measurePeriod*2
  end

  def handle_encounter_criteria(crit)
    encounter = Encounter.new()
    encounter.description = crit['description']
    measure_period_start_date = @measurePeriodStartDate.to_i
    measure_period_end_date = measure_period_start_date + @measurePeriod
    encounter.time = Time.at(rand(measure_period_start_date..measure_period_end_date))
    encounter.codes = {}
    encounter.codes['SNOMED-CT'] = crit['code_list_id']
    encounter
  end

end