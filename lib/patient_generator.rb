class Generator

  require 'health-data-standards'
  require 'namey'

  FEMALE_TITLES = ['Ms.', 'Mrs.', 'Miss', 'Dr.']
  MALE_TITLES = ['Mr.', 'Dr.']


  def initialize(measure, populations=["IPP", "NUMER"])
    @measure = measure
    @populations = populations
    #one year, in seconds
    @measurePeriod = 31540000
    @measurePeriodStartDate = Time.now - @measurePeriod*2

    # Handle criteria, populate list of criteria
    generate_criteria_path()

  end

  # For each population (in the case of CMS68v5, only IPP)
  #   Handle each precondition
  def generate_criteria_path
    @criteria_list = {characteristics: [], single_criteria: []}
    @populations.each do |pop|
      population = get_population_criteria(pop)
      population['preconditions'].each do |pre|
        handle_precondition(pre)
      end
      generate_criteria_based_fields()
      generate_patient() 
    end
  end

  def handle_precondition(pre)
    # is it a grouping condtion
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

  def handle_negation_criteria(precondition)
    return nil
  end

  def handle_data_criteria(id, temporal_references=[])
    crit = get_data_criteria(id)
    if crit["type"] == "derived"
      handle_grouping_critiera(crit,temporal_references)
    elsif crit["type"] == "characteristic"
      handle_patient_characteristic(crit,temporal_references)
    else
      handle_single_criteria(crit,temporal_references)
    end
  end

  def handle_and_criteria(precondition)
    precondition["preconditions"].each do |pre|
      handle_precondition(pre)
    end
  end

  def handle_or_critieria(precondition)
    len = precondition["preconditions"].length 
    pre = precondition["preconditions"][rand(len)]
    handle_precondition(pre)
  end

  def handle_patient_characteristic(crit, temporal_references = [])
    @criteria_list[:characteristics].push(crit)
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

  def handle_single_criteria(crit, temporal_references = [])
    @criteria_list[:single_criteria].push(crit)
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

  def generate_criteria_based_fields
    @fields = {}
    @criteria_list[:characteristics].each do |patient_char|
      if patient_char['definition'] == "patient_characteristic_birthdate"
        @fields[:birthdate] = handle_birthdate_criteria(patient_char)
      else
        handle_other_criteria(patient_char)
      end
    end
    @criteria_list[:single_criteria].each do |crit|
      if crit['definition'] == "encounter"
        unless @fields[:encounters]
          @fields[:encounters] = []
        end
        @fields[:encounters].push(handle_encounter_criteria(crit))
      elsif crit['definition'] == "procedure"
        unless @fields[:procedures]
          @fields[:procedures] = []
        end
        @fields[:procedures].push(handle_procedure_criteria(crit))
      else
      end
    end
  end

  def handle_birthdate_criteria(char)
    roughly_100_years = 3154000000
    earliest_birthdate = (Time.now - roughly_100_years).to_i
    char['temporal_references'].each do |ref|
      if ref['type'] == "SBS"
        reference = @measurePeriod
        age = ref['range']['low']['value']
        latest_birthdate = (Time.now - (age.to_i * 31540000)).to_i
        return Time.at(rand(earliest_birthdate..latest_birthdate))
      end
    end
  end

  def handle_other_criteria(crit)
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

  def handle_procedure_criteria(crit)
    procedure = Procedure.new()
    procedure
  end

  ############################################################################################
  # START: Utility functions
  #                          
  #         

  def get_population_criteria(population)
    pop_hqmf_id = @measure.population_ids[population]
    pop_id, pop_criteria = @measure.hqmf_document['population_criteria'].find do |population_id, population_criteria|
      population_criteria['hqmf_id'] == pop_hqmf_id
    end
    pop_criteria
  end

  def get_data_criteria(id)
    @measure.hqmf_document["data_criteria"][id]
  end

  def generate_patient
    @name_generator = Namey::Generator.new
    gender = rand(0..100) < 50 ? "F" : "M"
    name = (gender == "F") ? @name_generator.female : @name_generator.male
    patient = Record.new(:created_at => Time.now)
    patient.title = (gender == "F") ? FEMALE_TITLES[rand(0..(FEMALE_TITLES.length-1))] : MALE_TITLES[rand(0..(MALE_TITLES.length-1))]
    patient.first = name.split(' ')[0]
    patient.last = name.split(' ')[1]
    patient.gender = gender
    patient.birthdate = @fields[:birthdate]
    patient.expired = false
    # data criteria has an oid on it for a value set 
    if @fields[:encounters]
      @fields[:encounters].each do |encounter|
        patient.encounters.push(encounter)
      end
    end
    if @fields[:procedures]
      @fields[:procedures].each do |procedure|
        patient.procedures.push(procedure)
      end
    end
  end

end
