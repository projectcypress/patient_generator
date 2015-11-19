class ExecutionContext

  def initialize(criteria_list)
  	@criteria_list = criteria_list
  	@ruleList = []
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
  end

  def get_rule_list
  	return @ruleList
  end

end