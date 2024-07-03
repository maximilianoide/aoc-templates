# lib/aoc_helper.rb
require 'fileutils'
require 'net/http'
require 'uri'
require 'yaml'
require 'json'
require 'date'

module AOCHelper
  PROJECT_ROOT = File.expand_path('../..', __FILE__)

  class << self
    def get_project_dir(language, year)
      File.join(PROJECT_ROOT, "aoc-#{language}", "#{year}")
    end

    def prompt_for_year
      print "Enter the Advent of Code year: "
      STDIN.gets.chomp.to_i
    end

    def prompt_for_day
      print "Enter the day (1-25): "
      STDIN.gets.chomp.to_i
    end

    def prompt_for_part
      print "Enter the part (1 or 2): "
      STDIN.gets.chomp.to_i
    end

    def get_number_of_days(year)
      current_year = Date.today.year
      current_month = Date.today.month
      current_day = Date.today.day

      if year.to_i < current_year || (year.to_i == current_year && current_month == 12)
        25
      elsif year.to_i > current_year || (year.to_i == current_year && current_month < 12)
        0
      else
        [current_day, 25].min
      end
    end

    def download_all_inputs(project_dir, year)
      num_days = get_number_of_days(year)
      session_cookie = get_session_cookie

      (1..num_days).each do |day|
        day_dir = File.join(project_dir, format('day_%02d', day))
        input_file = File.join(day_dir, 'input.txt')
        download_input(year, day, session_cookie, input_file)
      end
    end

    def download_input(year, day, session_cookie, input_file)
      uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri)
        request['Cookie'] = "session=#{session_cookie}"
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          File.write(input_file, response.body.strip)
          puts "Input for Year #{year}, Day #{day} downloaded successfully."
        else
          puts "Failed to download input for Day #{day}. Status code: #{response.code}"
        end
      end
    end

    def get_session_cookie
      config_file = File.join(PROJECT_ROOT, '.aoc_config.yml')
      if File.exist?(config_file)
        config = YAML.load_file(config_file)
        return config['session_cookie'] if config && config['session_cookie']
      end

      print "Enter your Advent of Code session cookie: "
      session_cookie = STDIN.gets.chomp
      File.write(config_file, { 'session_cookie' => session_cookie }.to_yaml)
      session_cookie
    end

    def initialize_git_repo(project_dir)
      unless Dir.exist?(File.join(project_dir, '.git'))
        Dir.chdir(project_dir) do
          system('git init')
          system('git add .')
          system("git commit -m 'Initial commit for Advent of Code solutions'")
        end
      end
    end

    def update_progress(project_dir, day, part, execution_time)
      progress_file = File.join(project_dir, 'progress.json')
      progress = File.exist?(progress_file) ? JSON.parse(File.read(progress_file)) : {}
      progress[day] ||= {}
      progress[day][part] = execution_time
      File.write(progress_file, JSON.pretty_generate(progress))
    end

    def display_progress(project_dir, year)
      progress_file = File.join(project_dir, 'progress.json')
      return puts "No progress data available for #{year}" unless File.exist?(progress_file)

      progress = JSON.parse(File.read(progress_file))
      puts "Progress for Advent of Code #{year}:"
      puts "┌────┬────────┬────────┐"
      puts "│ Day│ Part 1 │ Part 2 │"
      puts "├────┼────────┼────────┤"
      
      (1..25).each do |day|
        day_progress = progress[day.to_s.rjust(2, '0')] || {}
        part1 = day_progress['1'] ? '✓' : ' '
        part2 = day_progress['2'] ? '✓' : ' '
        puts "│ #{day.to_s.rjust(2)} │   #{part1}    │   #{part2}    │"
      end
      
      puts "└────┴────────┴────────┘"
    end
  end
end
