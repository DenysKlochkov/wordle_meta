# frozen_string_literal: true

require 'parallel'
require 'etc'

require_relative './word_match'

class GuessModel
  attr_reader :words, :entropy_table

  def initialize(words:)
    @words = words
    @word_count = @words.count
    @process_count = Etc.nprocessors
  end

  # for each word
  # let metric be the average decrease of set entropy
  # (can be approximated as the ratio between number of possibilities after matching vs before)
  # for each possible secret
  def calculate_words_metrics(secret_sample: 1.0, given_secrets: nil, chunk_output: nil, use_secrets: false)
    secrets = given_secrets || @words.sample(@words.count * secret_sample * 1.0)
    secrets = @words.sample(1) if secrets.empty?

    words_per_process = @word_count / @process_count + 1.0
    words_per_process = words_per_process.round

    word_list = use_secrets ? secrets : @words
    @entropy_table = Parallel.map(@words.each_slice(words_per_process)) do |words_chunk|
      f = File.open([chunk_output, Parallel.worker_number].join('-'), 'w+') if chunk_output
      words_chunk.collect do |words_per_process|
        e = Matcher.calculate_entropy_metric_slow(matcher: word, list: word_list, secrets:)
        if chunk_output
          f = File.open([chunk_output, Parallel.worker_number].join('-'), 'a+')
          f.puts("#{word} - #{e}\n")
          f.close
        end
        [word, e]
      end
    end

    @entropy_table = @entropy_table.flatten(1)
    self
  end

  def test_word(word:, secret_sample: 1.0, given_secrets: nil)
    secrets = given_secrets || @words.sample(@words.count * secret_sample * 1.0)
    secrets = @words.sample(1) if secrets.empty?
    e = Matcher.calculate_entropy_metric_slow(matcher: word, list: @words, secrets:, remember_counts: true)
    [word, e]
  end

  def dump_to_file(file:)
    f = File.open(file, 'w+')
    return unless File.exist?(f)

    @entropy_table.sort_by { |z| -z.last.to_f }.each do |entry|
      f.puts("#{entry.join(' - ')}\n")
    end
  end
end

class Matcher
  @@dp = {}
  @@dp_filter_count = {}
  @@partial_counts = []

  class << self
    def dp
      @@dp
    end

    def dp_filter_count
      @@dp_filter_count
    end

    def partial_counts
      @@partial_counts
    end
  end

  def self.hash_key(matcher, secret)
    "#{matcher}|||#{secret}"
  end

  def self.hash_key_filter(matcher, secret)
    "#{matcher}|||#{secret}"
  end

  def self.reset
    @@dp = {}
    @@dp_filter_count = {}
    @@partial_counts = []
  end

  def self.match(matcher:, secret:)
    MatchObject.build(matcher:, secret:)
  end

  def self.filter_words_slow(match_object:, list:)
    match_object.filter_list(list:)
  end

  def self.filter_words_slow_count(match_object:, list:)
    match_object.filter_list_count(list:)
  end

  def self.calculate_entropy_metric_slow(matcher:, list:, secrets:, remember_counts: false)
    words_count = list.count
    secret_count = secrets.count
    entropy_metric = 0.0
    @@partial_counts = []
    
    secrets.each do |secret|
      m = match(matcher:, secret:)
      signature = m.get_filter_signature

      if @@dp_filter_count[signature]
        filtered_words_count = @@dp_filter_count[signature]
      else
        filtered_words_count = filter_words_slow_count(
          match_object: m,
          list:
        )
        @@dp_filter_count[signature] = filtered_words_count

      end

      @@partial_counts << [secret, filtered_words_count] if remember_counts
      entropy_metric += Math.log2(1.0 * words_count / filtered_words_count)
    end
    entropy_metric / secret_count
  end
end
