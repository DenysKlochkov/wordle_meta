require 'parallel'
require 'etc'

require_relative './word_match'



class GuessModel
  attr_reader :words
  attr_reader :entropy_table

  def initialize(words:, secret: nil)
    @words = words
    @word_count = @words.count
    @process_count = Etc.nprocessors
  end

  private

  def set_secret(secret = nil)
    return if @secret

    @secret = secret if secret && @words.include?(secret)
    @secret ||= @words.sample
    puts 'TODO: DEBUG: SECRET SET ' + @secret
    self
  end

  public

  # for each word
  # let metric be the average decrease of set entropy
  # (can be approximated as the ratio between number of possibilities after matching vs before)
  # for each possible secret
  # TODO: use threads, can be done in parallel
  def calculate_words_metrics(secret_sample: 1.0, given_secrets: nil, chunk_output: nil)
    secrets = given_secrets || @words.sample(@words.count * secret_sample * 1.0)
    secrets = @words.sample(1) if secrets.empty?

    words_per_process = @word_count / @process_count + 1.0
    words_per_process = words_per_process.round

    @entropy_table = Parallel.map(@words.each_slice(words_per_process)) do |words_chunk|
      if chunk_output
        f = File.open([chunk_output, Parallel.worker_number].join("-"), "w+")
      end
      words_chunk.collect.with_index do |word, _ind|
        e = Matcher.calculate_entropy_metric_slow(matcher: word, list: @words, secrets: secrets)
        if chunk_output
          f = File.open([chunk_output, Parallel.worker_number].join("-"), "a+")
          f.puts("#{word} - #{e}" + "\n")
          f.close()
        end
        [word, e]
      end
    end.flatten(1)


    self
  end

  def test_word(word:, secret_sample: 1.0, given_secrets: nil)
    secrets = given_secrets || @words.sample(@words.count * secret_sample * 1.0)
    secrets = @words.sample(1) if secrets.empty?
    e = Matcher.calculate_entropy_metric_slow(matcher: word, list: @words, secrets: secrets, remember_counts: true)
    [word, e]
  end

  def dump_to_file(file:)
    f = File.open(file, 'w+')
    return unless File.exist?(f)

    @entropy_table.sort_by{|z|-z.last.to_f}.each do |entry|
      f.puts(entry.join(' - ') + "\n")
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
    key = hash_key(matcher, secret)
    if @@dp[key]
      return MatchObject.new(
        word: matcher,
        green: @@dp[key][0],
        yellow: @@dp[key][1],
        black: @@dp[key][2]
      )
    end

    m = MatchObject.build(matcher: matcher, secret: secret)
    # @@dp[key] = m.values

    m
  end

  def self.filter_words_slow(match_object:, list:)
    match_object.filter_list(list: list)
  end

  def self.calculate_entropy_metric_slow(matcher:, list:, secrets: ,remember_counts: false)
    words_count = list.count
    secret_count = secrets.count
    entropy_metric = 0.0
    @@partial_counts = []
    secrets.each do |secret|
      m = match(matcher: matcher, secret: secret)
      signature = m.get_filter_signature
      if @@dp_filter_count[signature]
        filtered_words_count = @@dp_filter_count[signature]
      else
        filtered_words_count = filter_words_slow(
          match_object: m,
          list: list
        ).count + 1

        @@dp_filter_count[signature] = filtered_words_count
      end
      
      if remember_counts
        @@partial_counts << [secret, filtered_words_count]
      end

      entropy_metric += 1.0 * Math.log2(words_count / filtered_words_count)
    end

    entropy_metric / secret_count
  end
end
