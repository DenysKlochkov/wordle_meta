class MatchObject
  attr_reader :state

  def initialize(word:, green:, yellow:, black:)
    @green = green
    @yellow = yellow
    @black = black
    @state = word.split('').collect.with_index do |letter, ind|
      indicator = case ind
                  when *green
                    :x
                  when *yellow
                    :o
                  when *black
                    :-
                  end

      [letter, indicator]
    end
  end

  def self.build(matcher: , secret:)
    letters1 = matcher.split('')
    letters2 = secret.split('')
    letters2_dump = letters2.dup
    raise "Mismatch error #{matcher}, #{secret}" unless letters1.count == letters2.count

    green = []
    yellow = []
    black = []

    letters1.each.with_index do |letter, ind|
      if letters2[ind] == letter
        green << ind
        letters2_dump.delete_at(letters2_dump.index(letter))
      end
    end

    letters1.each.with_index do |letter, ind|
      next if green.include?(ind)
      if letters2_dump.include?(letter)
        yellow << ind
        letters2_dump.delete_at(letters2_dump.index(letter))
      else
        black << ind
      end
    end

    new(
      word: matcher,
      green: green,
      yellow: yellow,
      black: black
    )

  end

  def ==(other)
    other.class == self.class && other.state.collect(&:last) == state.collect(&:last)
  end

  def filter_list(list:)
    letters = @state.collect(&:first)
    g_letters = letters.values_at(*@green)
    y_letters = letters.values_at(*@yellow)
    b_letters = letters.values_at(*@black)

    non_green = @yellow + @black

    list.select do |o_word|
      other_letters = o_word.split('')
      next unless g_letters == other_letters.values_at(*@green)
      next unless (y_letters - (other_letters.values_at(*non_green))).empty?

      other_letters = other_letters.exclude_once(g_letters).exclude_once(y_letters)
      next unless (b_letters & other_letters).empty?
      
      true
    end
  end

  def filter_list_count(list:)
    letters = @state.collect(&:first)
    g_letters = letters.values_at(*@green)
    y_letters = letters.values_at(*@yellow)
    b_letters = letters.values_at(*@black)
    non_green = @yellow + @black

    list.select do |o_word|
      other_letters = o_word.split('')
      next unless g_letters == other_letters.values_at(*@green)
      next unless (y_letters - (other_letters.values_at(*non_green))).empty?

      other_letters = other_letters.exclude_once(g_letters).exclude_once(y_letters)
      next unless (b_letters & other_letters).empty?

      true
    end.count
  end

  def get_filter_signature
    # "#{@state.sort_by(&:first)}"
    "#{@state}"
  end

  def values
    [
      @green,
      @yellow,
      @black
    ]
  end

  def to_s
    print
  end

  def print
    puts "Word :     #{@state.collect(&:first).join('|')}"
    puts "Matches :  #{@state.collect(&:last).join('|')}"
  end
end
