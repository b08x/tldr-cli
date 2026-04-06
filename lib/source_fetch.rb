# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module SourceFetch
  GITHUB_RAW = 'https://raw.githubusercontent.com'

  def self.fetch(repo, path)
    cache[path] ||= begin
      url = "#{GITHUB_RAW}/#{repo}/#{path}"
      response = Net::HTTP.get_response(URI.parse(url))
      response.is_a?(Net::HTTPSuccess) ? response.body : nil
    end
  rescue StandardError => e
    warn "Fetch #{path}: #{e.message}"
    nil
  end

  def self.list(repo, dir)
    cache_key = "list:#{repo}:#{dir}"
    cache[cache_key] ||= begin
      url = "https://api.github.com/repos/#{repo}/contents/#{dir}"
      response = Net::HTTP.get_response(URI.parse(url))
      return [] unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).select { |f| f['type'] == 'file' }
    end
  rescue StandardError => e
    warn "List #{dir}: #{e.message}"
    []
  end

  def self.clear_cache
    @cache = {}
  end

  def self.cache
    @cache ||= {}
  end
  private_class_method :cache
end
