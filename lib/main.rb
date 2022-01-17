require_relative './utils'
require_relative './word_match'
require_relative './meta'

require 'benchmark'
require 'fileutils'
require 'descriptive_statistics'
require 'terminal-table'

# compares statistical metrics of values array at different level of sampling 
# for random and daisy-chaining strategy
# to that of a fully-sampled array ( final )
class DaisyChainTest
  RANDOM_TESTED_VALUES = [0.01, 0.1, 0.25, 0.5, 0.75, 0.8, 0.9]

  def initialize(word_count)
    @words = WordsReader.new(file: "../word_lists/words_#{word_count}.txt").read_words.words
    @model = GuessModel.new(words: @words)
    @final_table = final

    random_values = random
    table = [
      ["Random Sampling"],
      ["Sampling Value", "Median", "Mean", "Variance"]
    ]
    RANDOM_TESTED_VALUES.each.with_index do |value, index|
      v = random_values[index]
      table << [value, v.median, v.mean, v.variance]
    end

    puts Terminal::Table.new rows: table
    
    daisy = daisy_chain
    table = [
      ["Daisy Chaining"],
      ["Sampling Value", "Median", "Mean", "Variance"]
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
        given_secrets = last_secret.sort_by{|z|-z.last.to_f}.collect(&:first).last(@words.count * sampling_value)
      end

      g = @model.calculate_words_metrics(given_secrets: given_secrets)
      last_secret = g.entropy_table

      relative = g.entropy_table.collect.with_index do |value, ind|
        value[1] * 1.0 / @final_table[ind][1]
      end 
      relative
    end
  end


end

MAX_WORDS = 12595

def run(word_count = 200, secret_sample = 0.1)
  w = WordsReader.new(file: adjust_file_path( "../word_lists/words_#{word_count}.txt")).read_words.words
  FileUtils.mkdir_p "../output/#{word_count}words"
  g = GuessModel.new(words: w).calculate_words_metrics(
    secret_sample: secret_sample,
    chunk_output: adjust_file_path( "../output/#{word_count}words/sample_#{secret_sample}")
  )
end

def test_word(word, word_count = 200, secret_sample = 0.1)
  Matcher.reset
  w = WordsReader.new(file: adjust_file_path( "../word_lists/words_#{word_count}.txt")).read_words.words
  g = GuessModel.new(words: w).test_word(word: word, secret_sample: secret_sample)
end

def sample_words(word_count = 1000)
  file_name = "../word_lists/words_#{word_count}.txt"
  w = WordsReader.new(file: adjust_file_path( '../word_lists/words.txt')).read_words(limit: word_count).dump_words(file: adjust_file_path(file_name))
  file_name
end

def combine_words(word_count = 200, secret_sample = 0.1)
  reader = MultipleStreamsReader.new(
    file_names: [*0..11].collect{|i|adjust_file_path( "../output/#{word_count}words/sample_#{secret_sample}-#{i}") }
  ).read_words
  reader.dump_words(file: adjust_file_path( "../output/#{word_count}words/sample_#{secret_sample}-combined"))
  reader.remove_words_from_file(file: adjust_file_path( "../word_lists/words_#{word_count}.txt"))
  reader.clear_files
end

def sort_words(file: ,output:)
  w = WordsReader.new(file: adjust_file_path( file)).tap do |w_r|
    w_r.read_words
    w_r.sort_by{|w| -w.split(" - ").last.to_f}
    w_r.dump_words(file: adjust_file_path( output))
  end
end


# DaisyChainTest.new(500)
#TODO: gnuplot visualisations
# p test_word(ARGV[0], MAX_WORDS, 1.0)

# combine_words(MAX_WORDS, 1)
# sort_words(
#   file: "../output/12595words/sample_1-combined",
#   output: "../output/12595words/sample_1-combined-sorted"
# )

# run(MAX_WORDS, 1)