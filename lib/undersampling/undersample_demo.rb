# frozen_string_literal: true

require_relative '../main'

require 'descriptive_statistics'
require 'terminal-table'


# compares statistical metrics of values array at different level of sampling
# for random and daisy-chaining strategy
# to that of a fully-sampled array ( final )
class UndersamplingMethodsTest
  RANDOM_TESTED_VALUES = [0.01, 0.1, 0.25, 0.5, 0.75, 0.8, 0.9].freeze
  OUTPUT_TABLE_HEADER_PADDING = 25

  def initialize(word_count)
    @words = WordsReader.new(file: adjust_file_path("../word_lists/words_#{word_count}.txt")).read_words.words
    @model = GuessModel.new(words: @words)
  end
  
  def test(*methods)
    signatures = methods.empty? ? self.class.list_methods : methods
    
    final_table

    signatures.each do |signature|
      next unless respond_to?(signature, true)

      result = send(signature)
      table = [
        [signature.to_s.ljust(OUTPUT_TABLE_HEADER_PADDING, ' ')],
        ['Sampling Value', 'Median', 'Mean', 'Variance']
      ]
      RANDOM_TESTED_VALUES.each.with_index do |value, index|
        v = result[index]
        table << [value, v.median, v.mean, v.variance]
      end

      puts Terminal::Table.new rows: table
    end
  end

  def self.list_methods
    %i[random daisy_chain_high daisy_chain_low daisy_chain_combined]
  end
  
  private 

  def final_table
    @final_table ||= @model.calculate_words_metrics(secret_sample: 1.0).entropy_table
  end

  def random
    RANDOM_TESTED_VALUES.collect do |sampling_value|
      g = @model.calculate_words_metrics(secret_sample: sampling_value)
      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / final_table[ind][1]
      end
      relative
    end
  end

  def daisy_chain_high
    last_secret = []
    RANDOM_TESTED_VALUES.collect do |sampling_value|
      if last_secret.empty?
        given_secrets = @words.sample(@words.count * sampling_value)
        given_secrets = @words.sample(1) if given_secrets.empty?
      else
        given_secrets = last_secret.sort_by { |z| -z.last.to_f }.collect(&:first).first(@words.count * sampling_value)
      end

      g = @model.calculate_words_metrics(given_secrets:)
      last_secret = g.entropy_table

      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / final_table[ind][1]
      end
      relative
    end
  end

  def daisy_chain_low
    last_secret = []
    RANDOM_TESTED_VALUES.collect do |sampling_value|
      if last_secret.empty?
        given_secrets = @words.sample(@words.count * sampling_value)
        given_secrets = @words.sample(1) if given_secrets.empty?
      else
        given_secrets = last_secret.sort_by { |z| -z.last.to_f }.collect(&:first).last(@words.count * sampling_value)
      end

      g = @model.calculate_words_metrics(given_secrets:)
      last_secret = g.entropy_table

      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / final_table[ind][1]
      end
      relative
    end
  end

  def daisy_chain_combined
    last_secret = []
    RANDOM_TESTED_VALUES.collect do |sampling_value|
      if last_secret.empty?
        given_secrets = @words.sample(@words.count * sampling_value)
        given_secrets = @words.sample(1) if given_secrets.empty?
      else
        sorted = last_secret.sort_by { |z| -z.last.to_f }.collect(&:first)
        given_secrets = sorted.first(@words.count * sampling_value / 2.0) + sorted.last(@words.count * sampling_value / 2.0)
      end

      g = @model.calculate_words_metrics(given_secrets:)
      last_secret = g.entropy_table

      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / final_table[ind][1]
      end
      relative
    end
  end

end
