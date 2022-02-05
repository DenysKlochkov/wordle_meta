class Array
  def tally
    reduce({}){|a,b| a[b] ||= 0; a[b]+=1; a}
  end

  def exclude_once(other)
    d = self.dup
    other.each do |el|
      found_ind = d.index(el)
      d.delete_at(found_ind) if found_ind
    end
    d
  end
end

class WordsReader
  attr_reader :words

  def initialize(file:, **_params)
    @file = File.open(file, 'r')
    raise 'File not found' unless File.exist?(@file)
  end

  def read_words(delim: "\n",  word_length: 5, limit: nil)
    stream = @file.read
    @words = stream.split(delim)
    @words = @words.sample(limit).sort if limit
    @file.close
    self
  end

  def sort_by(&block)
    @words = @words.sort_by{ |w|
      block.call(w)
    }
  end

  def select(&block)
    @words.select{ |w|
      block.call(w)
    }
  end

  def select!(&block)
    @words = select(&block)
  end



  def dump_words(file:, delim: "\n")
    return false unless @words
    File.open(file, 'w+').write(@words.join(delim))
  end

end

class MultipleStreamsReader
  attr_reader :words

  def initialize(file_names: ,**_params)
    @file_names = file_names
    @files = @file_names.collect do |f_n| 
      file = File.open(f_n, 'r') 
      raise 'File not found' unless File.exist?(file)
      file
    end
  end

  def read_words(delim: "\n", word_length: 5, limit: nil)
    @words = []

    @words = @files.collect do |f|
      stream = f.read
      f.close()
      words =  stream.split(delim)
      words = words.select{|w| w.length > 0}
      
    end.flatten(1)

    @words = @words.sample(limit).sort if limit
    self
  end

  def clear_files
    @file_names.each do |f_n|
      File.open(f_n, 'w+')  
    end
  end

  def dump_words(file:, delim: "\n", given_words: nil, new_file: false)
    source =  given_words || @words 
    return false unless source

    File.open(file, new_file ? 'w+' : 'a+').write(source.join(delim)+delim)
  end

  def remove_words_from_file(file:, delim: "\n")
    read_f = File.open(file, 'r')
    write_file_name = file + "dump"
    
    raise 'File not found' unless File.exist?(read_f)
    
    previous_words = @words.collect{|z| z.split(" - ")[0]}
    words = read_f.read.split(delim)
    words.select!{|w| w unless previous_words.include?(w)}
    
    read_f.close()
    write_f = dump_words(file: write_file_name, delim: delim, given_words: words, new_file: true)
    File.rename(write_file_name, file)
  end

end


def adjust_file_path(file)
  [__dir__,file].join('/')
end