# tasks/javascript.rake
require 'fileutils'
require 'benchmark'
require_relative '../lib/aoc_helper'

namespace :javascript do
  desc 'Setup JavaScript project for Advent of Code'
  task :setup, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('javascript', year)
    
    create_javascript_project_structure(project_dir, year)
    AOCHelper.download_all_inputs(project_dir, year)
    AOCHelper.initialize_git_repo(File.join(AOCHelper::PROJECT_ROOT, "aoc-javascript"))
  end

  desc 'Run JavaScript solution'
  task :run, [:year, :day, :part] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    day = args[:day] || AOCHelper.prompt_for_day
    part = args[:part] || AOCHelper.prompt_for_part
    project_dir = AOCHelper.get_project_dir('javascript', year)
    
    run_javascript_solution(project_dir, year, day, part)
  end

  desc 'Run JavaScript tests'
  task :test, [:year, :day] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    day = args[:day] || AOCHelper.prompt_for_day
    project_dir = AOCHelper.get_project_dir('javascript', year)
    
    run_javascript_tests(project_dir, day)
  end

  desc 'Run all JavaScript tests'
  task :test_all, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('javascript', year)
    
    run_all_javascript_tests(project_dir)
  end

  desc 'Display progress'
  task :progress, [:year] do |t, args|
    year = args[:year] || AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir('javascript', year)
    
    AOCHelper.display_progress(project_dir, year)
  end
end

def create_javascript_project_structure(project_dir, year)
  FileUtils.mkdir_p project_dir
  num_days = AOCHelper.get_number_of_days(year)

  (1..num_days).each do |day|
    day_dir = File.join(project_dir, format('day_%02d', day))
    FileUtils.mkdir_p day_dir
    create_javascript_files(day_dir, day)
  end

  create_javascript_config_files(project_dir, year)
  create_helper_file(project_dir)
end

def create_javascript_files(day_dir, day)
  FileUtils.touch File.join(day_dir, 'input.txt')
  FileUtils.touch File.join(day_dir, 'test_input.txt')
  ['part1.js', 'part2.js'].each do |part|
    File.write(File.join(day_dir, part), javascript_solution_template(day, part))
  end
  File.write(File.join(day_dir, "day_#{format('%02d', day)}_spec.js"), javascript_test_template(day))
end

def create_javascript_config_files(project_dir, year)
  File.write(File.join(project_dir, 'README.md'), readme_content(year))
end

def create_helper_file(project_dir)
  FileUtils.mkdir_p File.join(project_dir, 'lib')
  File.write(File.join(project_dir, 'lib', 'helper.js'), javascript_helper_content)
end

def run_javascript_solution(project_dir, year, day, part)
  day = day.to_s.rjust(2, '0')
  part = part.to_s
  file_path = File.join(project_dir, "day_#{day}", "part#{part}.js")
  
  puts "Running Year #{year}, Day #{day}, Part #{part}"
  time = Benchmark.measure do
    system("bun #{file_path}")
  end
  
  execution_time = time.real.round(2)
  puts "Execution time: #{execution_time} seconds"
  
  AOCHelper.update_progress(project_dir, day, part, execution_time)
end

def run_javascript_tests(project_dir, day)
  day = day.to_s.rjust(2, '0')
  spec_file = File.join(project_dir, "day_#{day}", "day_#{day}_spec.js")
  system("bun test #{spec_file}")
end

def run_all_javascript_tests(project_dir)
  Dir.glob(File.join(project_dir, "day_*", "*_spec.js")).each do |spec_file|
    system("bun test #{spec_file}")
  end
end

# Template methods
def javascript_solution_template(day, part)
  <<~JAVASCRIPT
    import { readFileSync } from 'fs';
    import { join } from 'path';
    import { parseInput } from '../lib/helper.js';

    const input = readFileSync(join(__dirname, 'input.txt'), 'utf-8').trim();

    // Advent of Code #{Date.today.year} - Day #{day} - Part #{part[-1]}

    function solve(input) {
      // TODO: Implement solution
    }

    const answer = solve(input);
    console.log(`Answer: ${answer}`);
  JAVASCRIPT
end

def javascript_test_template(day)
  <<~JAVASCRIPT
    import { readFileSync } from 'fs';
    import { join } from 'path';
    import { describe, it, expect } from 'bun:test';
    import { parseInput } from '../lib/helper.js';

    const testInput = readFileSync(join(__dirname, 'test_input.txt'), 'utf-8').trim();

    describe('Day #{day} Tests', () => {
      it('Part 1', () => {
        const expected = 0; // TODO: Replace with expected result for part 1
        const result = solvePart1(testInput);
        expect(result).toBe(expected);
      });

      it('Part 2', () => {
        const expected = 0; // TODO: Replace with expected result for part 2
        const result = solvePart2(testInput);
        expect(result).toBe(expected);
      });

      function solvePart1(input) {
        // TODO: Implement part 1 solution
      }

      function solvePart2(input) {
        // TODO: Implement part 2 solution
      }
    });
  JAVASCRIPT
end

def javascript_helper_content
  <<~JAVASCRIPT
    export function parseInput(input) {
      return input.split('\\n');
    }

    // Example helper function
    export function sumOfDigits(number) {
      return number.toString().split('').reduce((sum, digit) => sum + parseInt(digit, 10), 0);
    }
  JAVASCRIPT
end

def readme_content(year)
  <<~MARKDOWN
    # Advent of Code #{year} - JavaScript Solutions

    This folder contains my solutions for Advent of Code #{year} implemented in JavaScript.

    ## Structure

    Each day's solution is in its own folder, named `day_XX`, where XX is the two-digit day number. Inside each day's folder, you'll find:

    - `input.txt`: The input data for the day's puzzle
    - `test_input.txt`: Test input data, if provided in the puzzle description
    - `part1.js`: Solution for Part 1 of the day's puzzle
    - `part2.js`: Solution for Part 2 of the day's puzzle
    - `day_XX_spec.js`: Test file for both parts of the day's puzzle

    ## Running Solutions

    To run a solution for a specific day and part:

    ```
    rake javascript:run[year,day,part]
    ```

    For example, to run part 1 of day 1 for #{year}:

    ```
    rake javascript:run[#{year},1,1]
    ```

    ## Running Tests

    To run tests for a specific day:

    ```
    rake javascript:test[year,day]
    ```

    To run all tests:

    ```
    rake javascript:test_all[year]
    ```

    ## Tracking Progress

    To view your progress:

    ```
    rake javascript:progress[year]
    ```

    ## Notes

    - Solutions are implemented with a focus on readability and simplicity.
    - Feel free to optimize or refactor the solutions as you see fit!

    Happy coding and enjoy Advent of Code #{year}!
  MARKDOWN
end

