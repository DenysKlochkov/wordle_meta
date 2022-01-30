require_relative './utils'
require_relative './word_match'
require_relative './meta'

require 'fileutils'

# compares statistical metrics of values array at different level of sampling 
# for random and daisy-chaining strategy
# to that of a fully-sampled array ( final )

MAX_WORDS = 12595

def run_final(word_count = 200, secret_sample = 0.1)
  Matcher.reset
  w = WordsReader.new(file: adjust_file_path( "../word_lists/words_#{word_count}.txt")).read_words.words
  secrets = WordsReader.new(file: adjust_file_path( "../word_lists/words_#{word_count}.backup.txt")).read_words.words
  FileUtils.mkdir_p "../output/#{word_count}words"
  g = GuessModel.new(words: w).calculate_words_metrics(
    secret_sample: secret_sample,
    given_secrets: secrets,
    use_secrets: true,
    chunk_output: adjust_file_path( "../output/#{word_count}words/sample_#{secret_sample}")
  )
end

def test_word(word, word_count = 200, secret_sample = 0.1)
  w = WordsReader.new(file: adjust_file_path( "../word_lists/words_#{word_count}.backup.txt")).read_words.words
  g = GuessModel.new(words: w).test_word(word: word, secret_sample: secret_sample)
end

def compare_words

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



if ARGV[0]=="run"
  run_final(MAX_WORDS, 1.0)
elsif ARGV[0]=="sort"
  sort_words(
    file: "../output/#{MAX_WORDS}words/sample_1.0-combined",
    output: "../output/#{MAX_WORDS}words/sample_1.0-combined-sorted"
  )
elsif ARGV[0]=="test" && ARGV[1]
  Matcher.reset
  ARGV[1..].each do |word|
    p test_word(
      word, MAX_WORDS, 1.0 
    )
  end
elsif ARGV[0]=="cleanup"
  combine_words(MAX_WORDS, 1.0)
end