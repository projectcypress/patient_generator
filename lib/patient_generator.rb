class Generator

  require 'health-data-standards'
  require 'namey'

  RELIGIOUS_AFFILIATION_NAME_MAP={'1'=>'Christian','2'=>'Jewish', '3'=>'Muslim', '4'=>'Jewish'}
  ETHNICITY_NAME_MAP={'2186-5'=>'Not Hispanic or Latino', '2135-2'=>'Hispanic Or Latino'}
  RACE_NAME_MAP={'1002-5' => 'American Indian or Alaska Native','2028-9' => 'Asian','2054-5' => 'Black or African American','2076-8' => 'Native Hawaiian or Other Pacific Islander','2106-3' => 'White','2131-1' => 'Other'}
  FEMALE_TITLES = ['Ms.', 'Mrs.', 'Miss', 'Dr.']
  MALE_TITLES = ['Mr.', 'Dr.']
  LANGUAGES = ['English', 'Spanish', 'Arabic']

  def initialize(measure, populations=["IPP"])
    @measure = measure
    @populations = populations
    #one year, in seconds
    @measurePeriod = 31540000

    # Handle criteria, populate list of criteria
    generate_criteria_path()

    generate_criteria_based_fields()

    # Using the populated criteria list, generate the patient
    generate_patient() 
  end

  # For each population (in the case of CMS68v5, only IPP)
  #   Handle each precondition
  def generate_criteria_path
    @criteria_list = {characteristics: [], single_criteria: []}
    @populations.each do |pop|
      population = get_population_criteria(pop)
      # MONGO: population.preconditions.each do |pre|
      population['preconditions'].each do |pre|
        handle_precondition(pre)
      end
    end
  end

  # Spits off data in different directions based on preconditons (logic): 
  # "NEGATION", "DATA", "AND", "OR"
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

  ############################################################################################
  # START: Handle precondition of type "NEGATION"                                            
  #                                    "REFERENCE" ["DATA (leaf)"]                           
  #                                    "CONJUNCTION CODE: All True" ["AND"]                  
  #                                    "CONJUNCTION CODE: At Least One True" ["OR"]          
  #
  #
  # TYPE "NEGATION"
  def handle_negation_criteria(precondition)
    return nil
  end
  #
  # TYPE "DATA ,leaf"
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
  #
  # TYPE "AND"
  def handle_and_criteria(precondition)
    precondition["preconditions"].each do |pre|
      handle_precondition(pre)
    end
  end
  #
  # TYPE "OR"
  def handle_or_critieria(precondition)
    len = precondition["preconditions"].length 
    pre = precondition["preconditions"][rand(len)]
    handle_precondition(pre)
  end
  #
  #
  # END: Handle precondition of type "NEGATION", "DATA, leaf", "AND", "OR"
  ############################################################################################


  ############################################################################################
  # START: Handle data criteria of type "DERIVED"                                            
  #                                     "CHARACTERISTIC"                                     
  #                                     !("DERIVED" V "CHARACTERISTIC") [call it, "OTHER"]   
  #
  #
  # TYPE "CHARACTERISTIC"
  def handle_patient_characteristic(crit, temporal_references = [])
    @criteria_list[:characteristics].push(crit)
  end
  #
  # TYPE "DERIVED"
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
  #
  # TYPE "OTHER"
  def handle_single_criteria(crit, temporal_references = [])
    @criteria_list[:single_criteria].push(crit)
  end
  #
  #
  # END: Handle data criteria of type "DERIVED", "CHARACTERISTIC", "OTHER"                   
  ############################################################################################


  ######################################################################
  # START: Functions used to handle "DERIVED" criteria
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
  # END: Functions used to handle "DERIVED" criteria
  ######################################################################


  def generate_criteria_based_fields
    @fields = {}
    @criteria_list[:characteristics].each do |patient_char|
      if patient_char['definition'] == "patient_characteristic_birthdate"
        @fields[:birthdate] = handle_birthdate_criteria(patient_char)
      else
        handle_other_criteria(patient_char)
      end
    end
  end

  ######################################################################
  # START: Functions used to handle "CHARACTERISTIC" criteria
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
  # END: Functions used to handle "CHARACTERISTIC" criteria
  ######################################################################

  ######################################################################
  # START: Functions used to handle "OTHER" criteria
  def handle_other_criteria(crit)
  end
  # END: Functions used to handle "OTHER" criteria
  ######################################################################

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

    # religious_affiliation_code = RELIGIOUS_AFFILIATION_NAME_MAP.keys()[rand(0..RELIGIOUS_AFFILIATION_NAME_MAP.size()-1)]
    # religious_affiliation_value = RELIGIOUS_AFFILIATION_NAME_MAP[religious_affiliation_code]
    # patient.religious_affiliation = {}
    # patient.religious_affiliation[religious_affiliation_code] = religious_affiliation_value 

    # ethnicity_code = ETHNICITY_NAME_MAP.keys()[rand(0..ETHNICITY_NAME_MAP.size()-1)]
    # ethnicity_value = ETHNICITY_NAME_MAP[ethnicity_code]
    # patient.ethnicity = {}
    # patient.ethnicity[ethnicity_code] = ethnicity_value 

    # race_code = RACE_NAME_MAP.keys()[rand(0..RACE_NAME_MAP.size()-1)]
    # race_value = RACE_NAME_MAP[race_code]
    # patient.race = {}
    # patient.race[race_code] = race_value 

    # patient.effective_time = Time.now
    # patient.languages = []
    # (1..rand[1..LANGUAGES.length]).each do |i|
    #   patient.languages.push(LANGUAGES[rand[0..LANGUAGES.length-1]])
    # end

    # data criteria has an oid on it for a value set 
    encounter = Encounter.new()
    encounter.description = @criteria_list[:single_criteria][0]['description']
    encounter.time = 0
    encounter.codes = {}

    patient.encounters.push(encounter)

  end


end
