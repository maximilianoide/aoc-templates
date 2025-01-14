# frozen_string_literal: true

# aoc_cli.rb
require 'thor'
require_relative 'lib/aoc_helper'

class AOCRunner < Thor
  include AOCHelper

  desc 'setup', 'Interactive setup for Advent of Code project'
  def setup
    puts AOCHelper.pastel.green('Welcome to Advent of Code setup!')
    language = AOCHelper.prompt.select('Select a language for Advent of Code:', AOCHelper::SUPPORTED_LANGUAGES)
    year = AOCHelper.prompt_for_year
    AOCHelper.setup_language(language, year)
  end

  desc 'clear_cache', 'Clear Advent of Code input and description cache'
  def clear_cache
    cache_dir = File.join(Dir.home, '.aoc_cache')
    if Dir.exist?(cache_dir)
      FileUtils.rm_rf(cache_dir)
      puts AOCHelper.pastel.green('Advent of Code cache cleared.')
    else
      puts AOCHelper.pastel.yellow('No cache directory found.')
    end
  end

  desc 'execute [LANGUAGE] [YEAR] [DAY] [PART]', 'Run an Advent of Code solution'
  method_option :submit, type: :boolean, aliases: '-s', desc: 'Automatically submit the solution output as the answer'
  def execute(language = nil, year = nil, day = nil, part = nil)
    # Interactive mode
    puts AOCHelper.pastel.green('Interactive mode:')

    # Infer or select language
    language ||= infer_language || AOCHelper.prompt.select('Select a language:', AOCHelper::SUPPORTED_LANGUAGES)

    # Select year
    year ||= AOCHelper.prompt_for_year
    project_dir = AOCHelper.get_project_dir(language, year)

    unless Dir.exist?(project_dir)
      puts AOCHelper.pastel.red("No solutions found for year #{year}.")
      return
    end

    # Select day
    day ||= AOCHelper.prompt_for_day(year)

    # Select part
    part ||= AOCHelper.prompt_for_part(project_dir, day, language)

    # Run the solution
    output = AOCHelper.run_solution(project_dir, year, day, part, language)

    return unless options[:submit]

    AOCHelper.submit_answer(year, day, part, output, AOCHelper.get_session_cookie)
  end

  desc 'progress [YEAR]', 'Display Advent of Code progress'
  def progress(year = nil)
    # Interactive mode
    puts AOCHelper.pastel.green('Interactive mode:')

    # Select year
    year ||= AOCHelper.prompt_for_year

    # Check progress from the leaderboard
    session_cookie = AOCHelper.get_session_cookie
    leaderboard_id = AOCHelper.get_leaderboard_id
    AOCHelper.check_progress(year, session_cookie, leaderboard_id)
  end

  desc 'submit [YEAR] [DAY] [PART] [ANSWER]', 'Submit an answer to Advent of Code'
  def submit(year = nil, day = nil, part = nil, answer = nil)
    # Interactive mode
    puts AOCHelper.pastel.green('Interactive mode:')

    # Select year
    year ||= AOCHelper.prompt_for_year

    # Select day
    day ||= AOCHelper.prompt_for_day(year)

    # Select part
    part ||= AOCHelper.prompt.select('Select the part:', [1, 2])

    # Enter answer
    answer ||= AOCHelper.prompt.ask('Enter your answer:')

    # Submit the answer
    session_cookie = AOCHelper.get_session_cookie
    AOCHelper.submit_answer(year, day, part, answer, session_cookie)
  end

  desc 'leaderboard [YEAR] [LEADERBOARD_ID]', 'Fetch Advent of Code leaderboard'
  def leaderboard(year = nil, leaderboard_id = nil)
    # Interactive mode
    puts AOCHelper.pastel.green('Interactive mode:')

    # Select year
    year ||= AOCHelper.prompt_for_year

    # Enter leaderboard ID
    leaderboard_id = AOCHelper.get_leaderboard_id

    # Fetch the leaderboard
    session_cookie = AOCHelper.get_session_cookie
    AOCHelper.fetch_leaderboard(year, leaderboard_id, session_cookie)
  end

  private

  # Infer language from existing aoc-<language> folders
  def infer_language
    languages = Dir.glob(File.join(AOCHelper::ADVENT_OF_CODE_DIR, 'aoc-*')).map do |path|
      File.basename(path).sub('aoc-', '')
    end

    if languages.size == 1
      languages.first
    elsif languages.size > 1
      AOCHelper.prompt.select('Multiple languages found. Select one:', languages)
    else
      nil
    end
  end
end

AOCRunner.start(ARGV)
