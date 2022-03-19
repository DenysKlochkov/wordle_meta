# frozen_string_literal: true

require_relative '../main'

require 'descriptive_statistics'
require 'terminal-table'


# compares statistical metrics of values array at different level of sampling
# for random and daisy-chaining strategy
# to that of a fully-sampled array ( final )
class DaisyChainTest
  RANDOM_TESTED_VALUES = [0.01, 0.1, 0.25, 0.5, 0.75, 0.8, 0.9].freeze

  def initialize(word_count)
    @words = WordsReader.new(file: "../word_lists/words_#{word_count}.txt").read_words.words
    @model = GuessModel.new(words: @words)
    @final_table = final

    random_values = random
    table = [
      ['Random Sampling'],
      ['Sampling Value', 'Median', 'Mean', 'Variance']
    ]
    RANDOM_TESTED_VALUES.each.with_index do |value, index|
      v = random_values[index]
      table << [value, v.median, v.mean, v.variance]
    end

    puts Terminal::Table.new rows: table

    daisy = daisy_chain
    table = [
      ['Daisy Chaining'],
      ['Sampling Value', 'Median', 'Mean', 'Variance']
    ]
    RANDOM_TESTED_VALUES.each.with_index do |value, index|
      v = daisy[index]
      table << [value, v.median, v.mean, v.variance]
    end

    puts Terminal::Table.new rows: table
  end

  def final
    @model.calculate_words_metrics(secret_sample: 1.0).entropy_table
  end

  def random
    RANDOM_TESTED_VALUES.collect do |sampling_value|
      g = @model.calculate_words_metrics(secret_sample: sampling_value)
      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / @final_table[ind][1]
      end
      relative
    end
  end

  def daisy_chain
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
        value[1] * 1.0 / @final_table[ind][1]
      end
      relative
    end
  end
end
