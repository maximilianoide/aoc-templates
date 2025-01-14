# frozen_string_literal: true

# lib/aoc_helper.rb
require 'fileutils'
require 'net/http'
require 'uri'
require 'yaml'
require 'json'
require 'date'
require 'nokogiri'
require 'reverse_markdown'
require 'tty-prompt'
require 'pastel'

module AOCHelper
  PROJECT_ROOT = File.expand_path('..', __dir__)
  ADVENT_OF_CODE_DIR = File.expand_path('../advent-of-code', PROJECT_ROOT)
  SUPPORTED_LANGUAGES = YAML.load_file(File.join(PROJECT_ROOT, 'languages.yml')).keys
  SUPPORTED_YEARS = (2015..Time.now.year).to_a

  class << self
    def prompt
      @prompt ||= TTY::Prompt.new
    end

    def pastel
      @pastel ||= Pastel.new
    end

    def get_project_dir(language, year)
      File.join(ADVENT_OF_CODE_DIR, "aoc-#{language}", year.to_s)
    end

    def prompt_for_year
      prompt.select('Select the Advent of Code year:', SUPPORTED_YEARS)
    end

    def prompt_for_day(year)
      days = (1..get_number_of_days(year)).to_a
      prompt.select('Select the day:', days)
    end

    def prompt_for_part(project_dir, day, language)
      day = day.to_s.rjust(2, '0')
      parts = []
      config = YAML.load_file('languages.yml')[language]
      extension = config['extension']
      part1_path = File.join(project_dir, "day_#{day}", "part1.#{extension}")
      part2_path = File.join(project_dir, "day_#{day}", "part2.#{extension}")

      parts << 1 if File.exist?(part1_path)
      parts << 2 if File.exist?(part2_path)
      if parts.empty?
        puts pastel.red("No solution files found for Day #{day}.")
        exit 1
      end

      prompt.select('Select the part:', parts)
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
      cache_dir = File.join(Dir.home, '.aoc_cache', year.to_s)
      FileUtils.mkdir_p(cache_dir)
      cache_file = File.join(cache_dir, "day_#{day}.txt")

      if File.exist?(cache_file)
        FileUtils.cp(cache_file, input_file)
        puts "Input for Year #{year}, Day #{day} loaded from cache."
        return
      end

      uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")
      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Cookie'] = "session=#{session_cookie}"
          response = http.request(request)

          if response.is_a?(Net::HTTPSuccess)
            File.write(input_file, response.body.strip)
            File.write(cache_file, response.body.strip)
            puts "Input for Year #{year}, Day #{day} downloaded successfully."
          else
            puts pastel.red("Failed to download input for Day #{day}. Status code: #{response.code}")
          end
        end
      rescue StandardError => e
        puts pastel.red("An error occurred while downloading input for Day #{day}: #{e.message}")
      end
    end

    def get_session_cookie
      config_file = File.join(PROJECT_ROOT, '.aoc_config.yml')
      if File.exist?(config_file)
        config = YAML.load_file(config_file)
        return config['session_cookie'] if config && config['session_cookie']
      end

      print 'Enter your Advent of Code session cookie: '
      session_cookie = $stdin.gets.chomp

      File.write(config_file, { 'session_cookie' => session_cookie }.to_yaml)

      session_cookie
    rescue StandardError => e
      puts pastel.red("Failed to read/write session cookie: #{e.message}")
      exit 1
    end

    def get_leaderboard_id
      config_file = File.join(PROJECT_ROOT, '.aoc_config.yml')
      if File.exist?(config_file)
        config = YAML.load_file(config_file)
        return config['leaderboard_id'] if config && config['leaderboard_id']
      end

      print 'Enter your Advent of Code leaderboard ID: '
      leaderboard_id = $stdin.gets.chomp

      File.write(config_file, { 'leaderboard_id' => leaderboard_id }.to_yaml)
    rescue StandardError => e
      puts pastel.red("Failed to read/write leaderboard ID: #{e.message}")
      exit 1
    end

    def initialize_git_repo(project_dir)
      language_dir = File.dirname(project_dir)
      return if Dir.exist?(File.join(language_dir, '.git'))

      Dir.chdir(language_dir) do
        system('git init')
        system('git add .')
        system("git commit -m 'Initial commit for Advent of Code solutions'")
      end
    rescue StandardError => e
      puts pastel.red("Failed to initialize Git repository: #{e.message}")
    end

    def create_year_readme(project_dir, year, language)
      readme_content = <<~MARKDOWN
        # Advent of Code #{year} - #{language.capitalize} Solutions

        This folder contains my solutions for Advent of Code #{year} implemented in #{language.capitalize}.

        ## Structure

        Each day's solution is in its own folder, named `day_XX`, where XX is the two-digit day number. Inside each day's folder, you'll find:

        - `input.txt`: The input data for the day's puzzle
        - `test_input.txt`: Test input data, if provided in the puzzle description
        - `part1.#{language}`: Solution for Part 1 of the day's puzzle
        - `part2.#{language}`: Solution for Part 2 of the day's puzzle

        ## Running Solutions

        To run a solution for a specific day and part:

        ```
        aoc run #{language} #{year} <day> <part>
        ```

        ## Tracking Progress

        To view your progress:

        ```
        aoc progress
        ```

        ## Notes

        - Solutions are implemented with a focus on readability and simplicity.
        - Feel free to optimize or refactor the solutions as you see fit!

        Happy coding and enjoy Advent of Code #{year}!
      MARKDOWN

      File.write(File.join(project_dir, 'README.md'), readme_content)
    rescue StandardError => e
      puts pastel.red("Failed to create README: #{e.message}")
    end

    def download_description(year, day, session_cookie, description_file)
      cache_dir = File.join(Dir.home, '.aoc_cache', year.to_s)
      FileUtils.mkdir_p(cache_dir)
      cache_file = File.join(cache_dir, "day_#{day}_description.md")

      if File.exist?(cache_file)
        FileUtils.cp(cache_file, description_file)
        puts "Description for Year #{year}, Day #{day} loaded from cache."
        return
      end

      uri = URI("https://adventofcode.com/#{year}/day/#{day}")
      begin
        html = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Cookie'] = "session=#{session_cookie}"
          response = http.request(request)
          response.body
        end

        doc = Nokogiri::HTML(html)
        description = doc.css('article.day-desc').to_s

        if description.empty?
          puts pastel.red("Failed to extract description for Year #{year}, Day #{day}.")
        else
          markdown = ReverseMarkdown.convert(description)
          File.write(description_file, markdown)
          File.write(cache_file, markdown)
          puts "Description for Year #{year}, Day #{day} downloaded and converted to Markdown successfully."
        end
      rescue StandardError => e
        puts pastel.red("An error occurred while downloading description for Day #{day}: #{e.message}")
      end
    end

    def download_all_descriptions(project_dir, year)
      num_days = get_number_of_days(year)
      session_cookie = get_session_cookie

      (1..num_days).each do |day|
        day_dir = File.join(project_dir, format('day_%02d', day))
        description_file = File.join(day_dir, 'description.md')
        download_description(year, day, session_cookie, description_file)
      end
    end

    def submit_answer(year, day, part, answer, session_cookie)
      uri = URI("https://adventofcode.com/#{year}/day/#{day}/answer")
      params = { level: part, answer: answer }

      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Post.new(uri)
          request['Cookie'] = "session=#{session_cookie}"
          request.set_form_data(params)
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          puts "Answer submitted successfully for Year #{year}, Day #{day}, Part #{part}."
        else
          puts pastel.red("Failed to submit answer. Status code: #{response.code}")
        end
      rescue StandardError => e
        puts pastel.red("An error occurred while submitting answer: #{e.message}")
      end
    end

    def check_progress(year, session_cookie, leaderboard_id)
      uri = URI("https://adventofcode.com/#{year}/leaderboard/private/view/#{leaderboard_id}.json")
      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Cookie'] = "session=#{session_cookie}"
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          leaderboard = JSON.parse(response.body)
          member = leaderboard['members'].values.find { |m| m['id'].to_s == leaderboard_id.to_s }

          if member
            puts pastel.green("Advent of Code #{year} Progress for #{member['name'] || "Anonymous #{member['id']}"}:")
            puts '┌──────┬────────┬────────┐'
            puts '│ Day  │ Part 1 │ Part 2 │'
            puts '├──────┼────────┼────────┤'

            (1..25).each do |day|
              day_progress = member['completion_day_level'][day.to_s] || {}
              part1 = day_progress.key?('1') ? '✓' : ' '
              part2 = day_progress.key?('2') ? '✓' : ' '
              puts "│ #{day.to_s.rjust(4)} │    #{part1}    │    #{part2}    │"
            end

            puts '└──────┴────────┴────────┘'
          else
            puts pastel.red('No progress data found for your account.')
          end
        else
          puts pastel.red("Failed to fetch leaderboard. Status code: #{response.code}")
        end
      rescue StandardError => e
        puts pastel.red("An error occurred while checking progress: #{e.message}")
      end
    end

    def fetch_leaderboard(year, leaderboard_id, session_cookie)
      uri = URI("https://adventofcode.com/#{year}/leaderboard/private/view/#{leaderboard_id}.json")
      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Cookie'] = "session=#{session_cookie}"
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          leaderboard = JSON.parse(response.body)
          puts "Leaderboard for Year #{year}:"
          leaderboard['members'].each do |id, member|
            puts "#{member['name'] || "Anonymous #{id}"}: #{member['local_score']} points"
          end
        else
          puts pastel.red("Failed to fetch leaderboard. Status code: #{response.code}")
        end
      rescue StandardError => e
        puts pastel.red("An error occurred while fetching leaderboard: #{e.message}")
      end
    end

    def create_project_structure(project_dir, year, language)
      FileUtils.mkdir_p project_dir
      num_days = get_number_of_days(year)

      (1..num_days).each do |day|
        day_dir = File.join(project_dir, format('day_%02d', day))
        FileUtils.mkdir_p day_dir
        create_language_files(day_dir, day, language)
      end

      create_language_config_files(project_dir, year, language)
    end

    def create_language_files(day_dir, day, language)
      config = YAML.load_file('languages.yml')[language]
      FileUtils.touch File.join(day_dir, 'input.txt')

      if language == 'go'
        file_path = File.join(day_dir, 'main.go')
        File.write(file_path, config['solution_template'].gsub('{year}', Date.today.year.to_s).gsub('{day}', day.to_s))
      else
        %w[part1 part2].each do |part|
          file_path = File.join(day_dir, "#{part}.#{config['extension']}")
          File.write(file_path,
                     config['solution_template'].gsub('{year}', Date.today.year.to_s).gsub('{day}', day.to_s).gsub(
                       '{part}', part[-1]
                     ))
        end
      end
    end

    def create_language_config_files(project_dir, year, language)
      config = YAML.load_file('languages.yml')[language]
      case language
      when 'javascript'
        File.write(File.join(project_dir, 'package.json'), '{"type": "module"}')
      when 'go'
        File.write(File.join(project_dir, 'go.mod'), "module aoc-#{year}\n\ngo 1.20\n")
      end
    end

    def run_solution(project_dir, year, day, part, language)
      config = YAML.load_file('languages.yml')[language]
      day = day.to_s.rjust(2, '0')
      part = part.to_s
      file_path = File.join(project_dir, "day_#{day}", "part#{part}.#{config['extension']}")

      puts pastel.blue("Running Year #{year}, Day #{day}, Part #{part}")

      # Benchmark the solution
      require 'benchmark'
      execution_time = Benchmark.realtime do
        output = `#{config['run_command']} #{file_path}`
        puts output
        output.strip
      end

      # Display detailed timing information
      puts pastel.green("Execution time: #{execution_time.round(2)} seconds")
    end

    def setup_language(language, year)
      project_dir = get_project_dir(language, year)
      create_project_structure(project_dir, year, language)
      download_all_inputs(project_dir, year)
      download_all_descriptions(project_dir, year)
      initialize_git_repo(project_dir)
      create_year_readme(project_dir, year, language)
    end
  end
end
