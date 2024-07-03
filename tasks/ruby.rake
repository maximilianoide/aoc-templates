# tasks/ruby.rake
require 'fileutils'
require 'benchmark'
require_relative '../lib/aoc_helper'

namespace :ruby do
  desc 'Setup Ruby project for Advent of Code'
  task :setup, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('ruby', year)
    
    create_ruby_project_structure(project_dir, year)
    AOCHelper.download_all_inputs(project_dir, year)
    AOCHelper.initialize_git_repo(File.join(AOCHelper::PROJECT_ROOT, "aoc-ruby"))
  end

  desc 'Run Ruby solution'
  task :run, [:year, :day, :part] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    day = args[:day] || AOCHelper.prompt_for_day
    part = args[:part] || AOCHelper.prompt_for_part
    project_dir = AOCHelper.get_project_dir('ruby', year)
    
    run_ruby_solution(project_dir, year, day, part)
  end

  desc 'Run Ruby tests'
  task :test, [:year, :day] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    day = args[:day] || AOCHelper.prompt_for_day
    project_dir = AOCHelper.get_project_dir('ruby', year)
    
    run_ruby_tests(project_dir, day)
  end

  desc 'Run all Ruby tests'
  task :test_all, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('ruby', year)
    
    run_all_ruby_tests(project_dir)
  end

  desc 'Display progress'
  task :progress, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('ruby', year)
    
    AOCHelper.display_progress(project_dir, year)
  end
end

def create_ruby_project_structure(project_dir, year)
  FileUtils.mkdir_p project_dir
  num_days = AOCHelper.get_number_of_days(year)

  (1..num_days).each do |day|
    day_dir = File.join(project_dir, format('day_%02d', day))
    FileUtils.mkdir_p day_dir
    create_ruby_files(day_dir, day)
  end

  create_ruby_config_files(project_dir, year)
  create_helper_file(project_dir)
end

def create_ruby_files(day_dir, day)
  FileUtils.touch File.join(day_dir, 'input.txt')
  FileUtils.touch File.join(day_dir, 'test_input.txt')
  ['part1.rb', 'part2.rb'].each do |part|
    File.write(File.join(day_dir, part), ruby_solution_template(day, part))
    FileUtils.chmod('+x', File.join(day_dir, part))
  end
  File.write(File.join(day_dir, "day_#{format('%02d', day)}_spec.rb"), ruby_test_template(day))
end

def create_ruby_config_files(project_dir, year)
  File.write(File.join(project_dir, 'README.md'), readme_content(year))
end

def create_helper_file(project_dir)
  FileUtils.mkdir_p File.join(project_dir, 'lib')
  File.write(File.join(project_dir, 'lib', 'helper.rb'), ruby_helper_content)
end

def run_ruby_solution(project_dir, year, day, part)
  day = day.to_s.rjust(2, '0')
  part = part.to_s
  file_path = File.join(project_dir, "day_#{day}", "part#{part}.rb")
  
  puts "Running Year #{year}, Day #{day}, Part #{part}"
  time = Benchmark.measure do
    system("ruby #{file_path}")
  end
  
  execution_time = time.real.round(2)
  puts "Execution time: #{execution_time} seconds"
  
  AOCHelper.update_progress(project_dir, day, part, execution_time)
end

def run_ruby_tests(project_dir, day)
  day = day.to_s.rjust(2, '0')
  spec_file = File.join(project_dir, "day_#{day}", "day_#{day}_spec.rb")
  system("ruby #{spec_file}")
end

def run_all_ruby_tests(project_dir)
  Dir.glob(File.join(project_dir, "day_*", "*_spec.rb")).each do |spec_file|
    system("ruby #{spec_file}")
  end
end

# Template methods
def ruby_solution_template(day, part)
  <<~RUBY
    #!/usr/bin/env ruby
    # frozen_string_literal: true

    require_relative '../lib/helper'

    # Advent of Code #{Date.today.year} - Day #{day} - Part #{part[-1]}

    input = File.read(File.join(__dir__, 'input.txt')).strip

    # Your solution goes here
    def solve(input)
      # TODO: Implement solution
    end

    answer = solve(input)
    puts "Answer: \#{answer}"
  RUBY
end

def ruby_test_template(day)
  <<~RUBY
    # frozen_string_literal: true

    require_relative '../lib/helper'
    require 'minitest/autorun'

    class Day#{day}Test < Minitest::Test
      def setup
        @test_input = File.read(File.join(__dir__, 'test_input.txt')).strip
      end

      def test_part1
        assert_equal expected_part1, solve_part1(@test_input)
      end

      def test_part2
        assert_equal expected_part2, solve_part2(@test_input)
      end

      private

      def expected_part1
        # TODO: Replace with expected result for part 1
        0
      end

      def expected_part2
        # TODO: Replace with expected result for part 2
        0
      end

      def solve_part1(input)
        # TODO: Implement part 1 solution
      end

      def solve_part2(input)
        # TODO: Implement part 2 solution
      end
    end
  RUBY
end

def ruby_helper_content
  <<~RUBY
    # frozen_string_literal: true

    # Add any Ruby-specific helper methods here

    def parse_input(input)
      input.lines(chomp: true)
    end

    # Example helper method
    def sum_of_digits(number)
      number.to_s.chars.map(&:to_i).sum
    end
  RUBY
end

def readme_content(year)
  <<~MARKDOWN
    # Advent of Code #{year} - Ruby Solutions

    This folder contains my solutions for Advent of Code #{year} implemented in Ruby.

    ## Structure

    Each day's solution is in its own folder, named `day_XX`, where XX is the two-digit day number. Inside each day's folder, you'll find:

    - `input.txt`: The input data for the day's puzzle
    - `test_input.txt`: Test input data, if provided in the puzzle description
    - `part1.rb`: Solution for Part 1 of the day's puzzle
    - `part2.rb`: Solution for Part 2 of the day's puzzle
    - `day_XX_spec.rb`: Test file for both parts of the day's puzzle

    ## Running Solutions

    To run a solution for a specific day and part:

    ```
    rake ruby:run[year,day,part]
    ```

    For example, to run part 1 of day 1 for #{year}:

    ```
    rake ruby:run[#{year},1,1]
    ```

    ## Running Tests

    To run tests for a specific day:

    ```
    rake ruby:test[year,day]
    ```

    To run all tests:

    ```
    rake ruby:test_all[year]
    ```

    ## Tracking Progress

    To view your progress:

    ```
    rake ruby:progress[year]
    ```

    ## Notes

    - Solutions are implemented with a focus on readability and simplicity.
    - Feel free to optimize or refactor the solutions as you see fit!

    Happy coding and enjoy Advent of Code #{year}!
  MARKDOWN
end
