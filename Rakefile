# Rakefile
require 'rake'
require 'fileutils'

SUPPORTED_LANGUAGES = Dir.glob(File.join('tasks', '*.rake')).map { |file| File.basename(file, '.rake') }
SUPPORTED_YEARS = (2015..Time.now.year).to_a

desc 'Interactive setup for Advent of Code project'
task :setup_aoc do
  puts "Welcome to Advent of Code setup!"
  language = select_option("Select a language for Advent of Code:", SUPPORTED_LANGUAGES)
  year = select_option("Select the Advent of Code year you want to set up:", SUPPORTED_YEARS)
  setup_language(language, year)
end

def select_option(prompt, options)
  puts prompt
  options.each_with_index do |option, idx|
    puts "#{idx + 1}. #{option.is_a?(String) ? option.capitalize : option}"
  end
  print "Enter the number of your choice: "
  choice = STDIN.gets.chomp.to_i
  options[choice - 1]
end

def setup_language(language, year)
  rake_file = File.join('tasks', "#{language}.rake")
  if File.exist?(rake_file)
    Rake.application.clear
    Rake.application.add_import(rake_file)
    Rake.application.load_imports

    load rake_file
    Rake::Task["#{language}:setup"].invoke(year)
  else
    puts "Error: Rake file for #{language} not found. Please ensure '#{rake_file}' exists."
  end
end

# Include tasks from specific directories
Dir.glob(File.join('tasks', '*.rake')).each { |r| import r }
