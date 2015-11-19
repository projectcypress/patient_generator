class Birthdate

  def initialize(lower_bound_age, upper_bound_age, period_start_date)
  	@period_start_date = period_start_date.to_i
  	@upper_bound_age ||=100
  	@lower_bound_age ||=0
  	@period_duration ||=31540000
  end

  def generate_random_birthdate
    earliest_birthdate = (@period_start_date - @upper_bound_age).to_i
    latest_birthdate = (@period_start_date - @lower_bound_age).to_i
  	return Time.at(rand(earliest_birthdate..latest_birthdate))
  end

end