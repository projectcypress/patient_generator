class Generator

  require 'health-data-standards'
  require 'namey'

  FEMALE_TITLES = ['Ms.', 'Mrs.', 'Miss', 'Dr.']
  MALE_TITLES = ['Mr.', 'Dr.']


  def initialize(measure, populations=["IPP", "NUMER"])
    @measure = measure
    @populations = populations
    criteria_list = DataCriteriaHelper.extract_data_criteria(@measure, @populations)
    executionContext = ExecutionContext.new(criteria_list)
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
    patient.birthdate = 123456
    patient.expired = false

  end

end
