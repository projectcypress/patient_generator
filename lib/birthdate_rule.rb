class BirthdateRule < Rule
   
  def execute(birthdate_value)
    @temporal_reference = {:lower_bound => 0, :upperbound => 100}
    # if temporal_reference.within_range(birthdate_value)
    # end
  end

  def handle_birthdate_criteria(char)
    roughly_100_years = 3154000000
    earliest_birthdate = (Time.now - roughly_100_years).to_i
    char['temporal_references'].each do |ref|
      if ref['type'] == "SBS"
        if ref['range']['low']
          reference = @measurePeriod
          age = ref['range']['low']['value']
          latest_birthdate = (Time.now - (age.to_i * 31540000)).to_i
          return Time.at(rand(earliest_birthdate..latest_birthdate))
        elsif ref['range']['high']
          reference = @measurePeriod
          age = ref['range']['high']['value']
          latest_birthdate = (Time.now - (age.to_i * 31540000)).to_i
          return Time.at(rand(earliest_birthdate..latest_birthdate))
        end
      end
    end
  end


end