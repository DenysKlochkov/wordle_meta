class WordsReader
  attr_reader :words

  def initialize(file:, **_params)
    @file = File.open(file, 'r')
    raise 'File not found' unless File.exist?(@file)
  end

  def read_words(delim: "\n", filter: true, word_length: 5, limit: nil)
    stream = @file.read
    @words = stream.split(delim)
    @words.select! { |w| w if w.length == word_length } if filter
    @words = @words.sample(limit).sort if limit
    @file.close
    self
  end

  def dump_words(file:, delim: "\n")
    return false unless @words
    File.open(file, 'w+').write(@words.join(delim))
  end
end