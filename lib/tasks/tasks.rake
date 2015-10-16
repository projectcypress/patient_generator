namespace :cypress do
  
  # Mongoid.load!('../../mongoid.yml', :development)

  # For now, this will be geared toward CMS68
  desc 'Create a patient that can qualify for the IPP of given measure'
  task :patient_generation, [:measure] do |t, args|

    measure_directory = '../bundle-2.7.0/measures/ep'
    file_path = File.join(measure_directory, args.measure + '.json')
    puts "################################"
    puts "Finding measure: #{args.measure}"
    puts "################################"

    # Check to see that a valid measure was given and exists in the measure directory
    if File.exists?(file_path)
      file = File.read(file_path)
      data_hash = JSON.parse(file)
      psuedo_mongo_object = MongoWrapper.new(data_hash)
      patient = Generator.new(psuedo_mongo_object)
    else
      puts "File not found"
    end
  end

end