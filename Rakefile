require 'json'
require 'colorize'
require 'rake'
require 'rspec/core/rake_task'

# Load the test configuration data
config = JSON.parse(File.read('tests.json'))
puts config.to_s.colorize(:magenta) if ENV['DEBUG']

# Set the SSH & sudo password from the config unless the user has over-ridden
# them
ENV['SUDO_PASSWORD'] = config['password'] unless ENV.has_key?('SUDO_PASSWORD')
ENV['LOGIN_PASSWORD'] = config['password'] unless ENV.has_key?('LOGIN_PASSWORD')

# Gather the Rake tasks to define from the config
tasks = config['tasks']
topologies = config['topologies']

# Provide some useful information if the user doesn't specify which tests to
# run
task :default do
  puts 'Usage: rake <tests> <topology> [<target>]'
  puts
  puts "Available tests are: #{tasks.map{|t| t['name']}.join(', ')}"
  puts "Available topologies are: #{topologies.join(', ')}"
  puts
  puts 'For example, "rake ospfunnum 2s" will run the OSPF Unnumbered tests for a 2-switch topology'
  puts '"rake ospfunnum 2s leaf1" will run the OSPF Unnumbered tests for a 2-switch topology on "leaf1" only'
  abort
end

# Print usage information of the user hasn't passed valid arguments
Rake::Task['default'].invoke if ARGV.length < 2 or ARGV.length > 3

# By default the tests are run on every host within the given topology, but an
# optional third argument allows the user to specify a single host to run the
# tests on; if one was passed, remember the host details and make sure ARGV is
# consistent
target_host = 'all'

if ARGV.length == 3
  target_host = ARGV.pop

  # Create a no-op task for it to keep Rake happy
  task target_host.to_sym do ; end
end
puts "Target host is #{target_host}".colorize(:magenta) if ENV['DEBUG']

# Helper method for finding the correct set of tests to run for any given
# target; returns the default set if there are no specific tests for a target
def find_set(task, target)
  default_set, target_set = ''
  task['sets'].each do |task_set|
    default_set = task_set['set'] if task_set['target'] == 'default'
    target_set = task_set['set'] if task_set['target'] == target
  end
  target_set ||= default_set
end

# Define a top-level Rake task for each task defined, and set the correct
# environment variables and test set to be run
tasks.each do |t|
  desc "Run the #{t['name']} serverspec tests"
  task t['name'].to_sym do
    # Extreme hackery to get some sensible command line arguments: take the
    # last argument passed to Rake and treat it as an argment, and then subvert
    # Rake by creating and empty task for it to run (Rake treats each argument
    # as a target, so if we don't then it will complain that the target '2s'
    # doesn't exist, for example)
    topology = ARGV.last

    # Print usage information of the user hasn't passed a valid topology
    unless topologies.include? topology
      puts "'#{topology}' is not a valid topology".colorize(:red)
      Rake::Task['default'].invoke
    end

    # Create a no-op task for it to keep Rake happy
    task topology.to_sym do ; end

    # Set the topology for the upstream tests
    ENV['TOPOLOGY'] = topology

    # Each set of tests is run once per. host, so keep track of how many hosts
    # failed
    failures = 0

    t['targets'][topology].each do |target|
      # Skip the other targets if the user has specifed a single target
      next unless target_host == 'all' || target_host == target

      begin
        ENV['TARGET_HOST'] = target
        target_set = find_set(t, target)
        Rake::Task['spec:run'].execute(name: t['name'], target: target, set: target_set)
      rescue Exception => e
        puts "Serverspec tests for #{target} failed: #{e.class} #{e.message}".colorize(:red)
        failures += 1
      end
    end
    if failures > 0
      puts "#{failures} of #{t['targets'][topology].length} hosts failed".colorize(:red)
    else
      puts "All tests passed succesfully".colorize(:green)
    end
  end
end

namespace :spec do
  task :run, [:name, :target, :set] do |_, args|
    puts "Running tests #{args[:name]} on #{args[:target]}".colorize(:blue)

    # Define and invoke a new RSpec task for all of the test sets this test
    # requires
    taskname = "#{args[:name]}#{args[:target]}"
    RSpec::Core::RakeTask.new("spec:#{taskname}".to_sym) do |t|
      t.pattern = FileList[args[:set].map{|el| "spec/#{el}/*_spec.rb"}]
    end
    Rake::Task["spec:#{taskname}"].execute
  end
end
