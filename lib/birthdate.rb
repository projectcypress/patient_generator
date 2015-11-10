class Birthdate

  field :lower_bound_age, type: Integer
  field :upper_bound_age, type: Integer
  field :period_start_date, type: Integer
  field :period_duration, type: Integer

  def initialize(lower_bound_age, upper_bound_age, period_start_date)
  	self.period_start_date = period_start_date.to_i

  	self.upper_bound_age ||=100
  	self.lower_bound_age ||=0
  	self.period_duration ||=31540000
  end

  def generate_random_birthdate
    earliest_birthdate = (period_start_date - upper_bound_age).to_i
    latest_birthdate = (period_start_date - lower_bound_age).to_
  	return Time.at(rand(earliest_birthdate..latest_birthdate))
  end


end
