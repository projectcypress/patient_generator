require 'rake'
require 'rake/testtask'
require 'fileutils'
require 'pry'
require 'json'

require_relative 'lib/patient_generator'
require_relative 'lib/temporal_reference'
require_relative 'lib/birthdate'
require_relative 'lib/rule'
require_relative 'lib/birthdate_rule'
require_relative 'lib/procedure_rule'
require_relative 'lib/encounter_rule'

require_relative 'lib/execution_context'

require_relative 'lib/helpers/data_criteria_helper'

# Pull in any rake task defined in lib/tasks
Dir['lib/tasks/**/*.rake'].sort.each do |ext|
  load ext
end

desc "Run basic tests"
Rake::TestTask.new(:test_unit) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
end

task :test => [:test_unit] do
  system("open coverage/index.html")
end

task :default => [:test]
