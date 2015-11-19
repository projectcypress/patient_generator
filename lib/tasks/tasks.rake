namespace :cypress do
  
  Mongoid.load!('../patient_generator/mongoid.yml', :development)

  # For now, this will be geared toward CMS68
  desc 'Create a patient that can qualify for the IPP of given measure'
  task :patient_generation, [:measure] do |t, args|
    puts "################################"
    puts "Finding measure: #{args.measure}"
    puts "################################"
    test_measure = HealthDataStandards::CQM::Measure.where({cms_id: args.measure})
    # Check to see that a valid measure was given and exists in the measure directory
    if test_measure.count == 1
      measure = test_measure.first
      patient = Generator.new(measure)
    elsif test_measure.count > 1
      measure = test_measure.first
      patient = Generator.new(measure, ["IPP"])
    else
      puts "Measure not found"
    end
  end

  desc 'Birthdate Test'
  task :birthdate_test, [:lower_age, :upper_age, :period_start_date] do |t, args|
    puts "################################"
    puts "Finding birthdate: between #{args.lower_age} and #{args.upper_age} years old at time #{args.period_start_date}"
    puts "################################"
    birthdate = Birthdate.new(args.lower_age, args.upper_age, Time.now)
  end

  desc 'Rules Tests'
  task :rules_tests, [:source_data_criteria, :type, :temporal_references] do |t, args|
    rule = Rule.new(args)
  end

  desc 'Temporal References Tests'
  task :temporal_references_tests, [:param] do |t, args|
    
  end

  desc 'Birthdate Rules Tests'
  task :birthdate_rules_tests, [:source_data_criteria, :type, :temporal_references] do |t, args|
    birthdateRule = BirthdateRule.new(args, ['a', 'b'])
    binding.pry

  end

  desc 'Execution Context Tests'
  task :execution_context_tests, [:criteria_list, :measure] do |t, args|
    executionContext = ExecutionContext.new(args.criteria_list)
  end


end