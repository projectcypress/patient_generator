class Generator

  require 'health-data-standards'
  # require 'active_support'
  require 'namey'

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
    female_titles = ["Ms.", "Mrs.", "Miss", "Dr."]
    male_titles = ["Mr.", "Dr."]

    patient = Record.new()
    patient.title = (gender == "F") ? female_titles[rand(0..(female_titles.length-1))] : male_titles[rand(0..(male_titles.length-1))]
    patient.first = name.split(' ')[0]
    patient.last = name.split(' ')[1]
    patient.gender = gender
    patient.birthdate = @fields[:birthdate]
    
    patient.deathdate = 00000000
    patient.religious_affiliation = {}
    patient.effective_time = 10000000
    patient.race = {}
    patient.ethnicity = {}
    patient.languages = ["English", "Italian"]
    patient.test_id = nil
    patient.marital_status = {}
    patient.medical_record_number = "N/A"
    patient.medical_record_assigner = "N/A"
    patient.expired = false

    puts patient.title

  end


end
