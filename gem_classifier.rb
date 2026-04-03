#!/usr/bin/env ruby
# frozen_string_literal: true

# Gem Classifier - Ruby gem categorization with LLM enhancement
# Usage: ruby gem_classifier.rb <csv_file> [--out output_dir]

require 'json'
require 'yaml'
require 'openssl'
require 'net/http'
require 'uri'
require 'optparse'
require 'fileutils'

require 'csv'

module GemClassifier
  # Configuration
  RUBYGEMS_URL = 'https://rubygems.org/api/v1/gems/%s.json'
  RATE_LIMIT_DELAY = 0.5
  LLM_BATCH_SIZE = 10
  LLM_RATE_DELAY = 0.5

  # Cache files
  CACHE_FILE = 'gem_cache.json'
  LLM_CACHE_FILE = 'llm_cache.json'

  # LLM Configuration
  LLM_ENDPOINT = ENV.fetch('DEVSTRAL_ENDPOINT', 'https://api.mistral.ai/v1/chat/completions')
  LLM_API_KEY = ENV['MISSTRAL_API_KEY']
  LLM_MODEL = ENV.fetch('DEVSTRAL_MODEL', 'devstral-small')

  CATEGORIES = %w[
    runtime_substrate framework_integration boundary_interface
    application_capability policy_enforcement observability
    developer_experience build_delivery
  ].freeze

  # Initialize caches
  def self.load_cache(path)
    File.exist?(path) ? JSON.parse(File.read(path)) : {}
  end

  def self.save_cache(path, data)
    File.write(path, JSON.pretty_generate(data))
  end

  @gem_cache = load_cache(CACHE_FILE)
  @llm_cache = load_cache(LLM_CACHE_FILE)

  class << self
    def run(csv_path, output_dir: 'output')
      FileUtils.mkdir_p(output_dir)
      results = process_csv(csv_path, output_dir)
      print_summary(results)
    end

    private

    def process_csv(csv_path, output_dir)
      results = Hash.new { |h, k| h[k] = [] }
      total = count_rows(csv_path)

      print_header(total)

      batch = []
      processed = 0

      CSV.foreach(csv_path, headers: true) do |row|
        name = row['name'] || row['gem'] || next
        group = row['group']

        print_progress(name, processed, total)

        info = fetch_gem_info(name)
        sleep(RATE_LIMIT_DELAY)

        classification, signals, conf, deps = classify_gem(name, info, group)

        if conf < 0.7
          batch << [name, info, deps, classification, signals]

          if batch.size >= LLM_BATCH_SIZE
            print_status "Processing LLM batch (#{batch.size})"
            process_batch(batch, results)
            batch = []
          end
        else
          finalize(name, classification, signals, deps, info, results)
        end

        processed += 1
      end

      process_batch(batch, results) if batch.any?

      save_results(results, output_dir)
      results
    end

    def count_rows(path)
      File.readlines(path).count - 1 # subtract header
    end

    def print_header(total)
      puts '═' * 60
      puts '  Ruby Gem Classifier'
      puts '  Analyzing gems via RubyGems API & LLM'
      puts '═' * 60
      puts "  Total gems: #{total}"
      puts '═' * 60
      puts
    end

    def print_progress(name, current, total)
      pct = ((current.to_f / total) * 100).round(1)
      print "\r  [#{pct}%] Analyzing #{name.ljust(30)}"
      $stdout.flush
    end

    def print_status(msg)
      puts "\n  #{msg}"
    end

    def fetch_gem_info(name)
      return @gem_cache[name] if @gem_cache.key?(name)

      uri = URI.parse(RUBYGEMS_URL % name)
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        @gem_cache[name] = data
        save_cache(CACHE_FILE, @gem_cache)
        data
      end
    rescue StandardError
      nil
    end

    def classify_gem(name, info, group = nil)
      lname = name.downcase
      deps = info ? info.dig('dependencies', 'runtime')&.map { |d| d['name'] } : []

      classification = { 'primary' => 'application_capability', 'secondary' => nil }
      signals = { 'rails' => false, 'external_io' => false, 'native_ext' => false }
      confidence = 0.6

      # Heuristics
      if lname.include?('active_support') || lname.include?('core_ext') || lname.start_with?('dry-')
        classification['primary'] = 'runtime_substrate'
        confidence += 0.2
      elsif deps.include?('railties') || lname.include?('rails') || lname.include?('engine') || lname.include?('sidekiq')
        classification['primary'] = 'framework_integration'
        signals['rails'] = true
        confidence += 0.3
      elsif lname.include?('http') || lname.include?('faraday') || lname.include?('aws') || lname.include?('google')
        classification['primary'] = 'boundary_interface'
        signals['external_io'] = true
        confidence += 0.2
      elsif lname.include?('pundit') || lname.include?('auth') || lname.include?('jwt')
        classification['primary'] = 'policy_enforcement'
        confidence += 0.2
      elsif lname.include?('sentry') || lname.include?('datadog') || lname.include?('newrelic')
        classification['primary'] = 'observability'
        signals['external_io'] = true
        confidence += 0.2
      elsif group == 'development' || group == 'test' || lname.include?('rspec') || lname.include?('rubocop') || lname.start_with?('tty-')
        classification['primary'] = 'developer_experience'
        confidence += 0.3
      end

      signals['native_ext'] = true if info && info['platform'] && info['platform'] != 'ruby'

      [classification, signals, confidence, deps || []]
    end

    def build_prompt(name, info, deps)
      <<~PROMPT
        Classify this Ruby gem into ONE category:
        - runtime_substrate
        - framework_integration
        - boundary_interface
        - application_capability
        - policy_enforcement
        - observability
        - developer_experience
        - build_delivery

        Gem: #{name}
        Description: #{info ? info['info'] : ''}
        Dependencies: #{deps.join(', ')}

        Return JSON only: {"primary":"...","confidence":0.0}
      PROMPT
    end

    def call_llm(prompt)
      key = Digest::SHA256.hexdigest(prompt)
      return @llm_cache[key] if @llm_cache.key?(key)

      uri = URI.parse(LLM_ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{LLM_API_KEY}"
      request['Content-Type'] = 'application/json'
      request.body = JSON.dump({
                                 model: LLM_MODEL,
                                 messages: [{ role: 'user', content: prompt }],
                                 temperature: 0
                               })

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        text = result.dig('choices', 0, 'message', 'content')
        parsed = JSON.parse(text)
        @llm_cache[key] = parsed
        save_cache(LLM_CACHE_FILE, @llm_cache)
        parsed
      end
    rescue StandardError
      nil
    end

    def process_batch(batch, results)
      batch.each do |name, info, deps, classification, signals|
        prompt = build_prompt(name, info, deps)
        llm = call_llm(prompt)
        sleep(LLM_RATE_DELAY)

        classification['primary'] = llm['primary'] if llm && llm['confidence'].to_f > 0.6

        finalize(name, classification, signals, deps, info, results)
      end
    end

    def finalize(name, classification, signals, deps, info, results)
      entry = {
        'name' => name,
        'classification' => classification,
        'role' => {
          'description' => info ? info['info'] : '',
          'attaches_to' => classification['primary'].split('_').first
        },
        'capabilities' => [],
        'risks' => score_gem(classification, deps),
        'signals' => signals,
        'usage_patterns' => [],
        'failure_modes' => []
      }

      results[classification['primary']] << entry
    end

    def score_gem(classification, deps)
      invasiveness = case classification['primary']
                     when 'runtime_substrate' then 5
                     when 'framework_integration' then 4
                     when 'boundary_interface' then 2
                     when 'developer_experience' then 1
                     else 3
                     end

      coupling = [4, [1, deps.size / 3 + 1].max].min
      leak = case classification['primary']
             when 'boundary_interface' then 'high'
             when 'framework_integration' then 'medium'
             else 'low'
             end

      { 'invasiveness' => invasiveness, 'coupling' => coupling, 'abstraction_leak' => leak }
    end

    def save_results(results, output_dir)
      results.each do |category, gems|
        File.write("#{output_dir}/#{category}.yaml", YAML.dump(gems, canonical: false))
      end
    end

    def print_summary(results)
      puts "\n" + '═' * 60
      puts '  Classification Summary'
      puts '═' * 60
      results.sort.each do |category, gems|
        puts "  #{category.ljust(30)} #{gems.size.to_s.rjust(3)} gems"
      end
      puts '═' * 60
    end
  end
end

if __FILE__ == $0
  output = 'output'
  OptionParser.new do |opts|
    opts.on('-o', '--out DIR', 'Output directory') { |v| output = v }
  end.parse!

  GemClassifier.run(ARGV[0], output_dir: output)
end
