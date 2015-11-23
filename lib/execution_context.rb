class ExecutionContext

  def initialize(measure, populations)
    @measure = measure
    @populations = populations
  	@criteria_list = @criteria_list = DataCriteriaHelper.extract_data_criteria(@measure, @populations)

  	@ruleList = []
  	@sortedRuleList = {:birthdate => []}

    @measurePeriod = @measure['hqmf_document']['measure_period']

    for criteria in @criteria_list
      if criteria['definition'] == 'patient_characteristic_birthdate'
      	rule = BirthdateRule.new(criteria, @criteria_list)
      elsif criteria['definition'] == 'encounter'
      	rule = Rule.new(criteria, @criteria_list)
      else
      	rule = Rule.new(criteria, @criteria_list)
      end
      @ruleList.push rule
    end
    sort_rules()
  end

  def sort_rules
  	for rule in @ruleList
  	  if rule.class.name == "BirthdateRule"
  	  	@sortedRuleList[:birthdate].push rule
  	  end
  	end
  end

  def execute_birthdate_rules(initial_birthdate)
    birthdate = initial_birthdate
    for rule in @sortedRuleList[:birthdate]
      birthdate = rule.execute(birthdate)
    end
    birthdate
  end

################### START: UTIL ###################
  def get_rule_list
  	return @ruleList
  end

  def get_criteria_list
    return @criteria_list
  end

  def get_measure_period
    return @measurePeriod
  end

  def get_measure
    return @measure
  end



################### END: UTIL ###################

end

# GLOBAL OBJECTS IN THIS CONTEXT:

  	# @criteria_list
  	# @ruleList  .... turns criteria list into a bunch of rules 
  	# @sortedRuleList .... a set of rules for a given cahracteristic ..  

  	# Need a global measure period and patient?