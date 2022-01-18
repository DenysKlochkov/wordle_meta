require 'test/unit'
require_relative './../meta'
require_relative './../utils'
require_relative './../word_match'


class Tests < Test::Unit::TestCase
  def test_matches
    #full match
    m1 = MatchObject.build(matcher:"dummy", secret:"dummy")
    assert_equal(m1.values, [[0,1,2,3,4],[],[]])

    #partial match
    m2 = MatchObject.build(matcher:"rummy", secret:"dummy")
    assert_equal(m2.values, [[1,2,3,4],[],[0]])

    #partial match with green letter
    m3 = MatchObject.build(matcher:"yummy", secret:"dummy")
    assert_equal(m3.values, [[1,2,3,4],[],[0]])

    #yellow letter
    m4 = MatchObject.build(matcher:"yumms", secret:"dummy")
    assert_equal(m4.values, [[1,2,3],[0],[4]])

    #yellow and green letters
    m5 = MatchObject.build(matcher:"apple", secret:"puppy")
    assert_equal(m5.values, [[2],[1],[0,3,4]])
  end

  def test_filtering
    m1 = MatchObject.build(matcher:"rommy", secret:"dummy")
    filtered1 = m1.filter_list(
      list: [
        "tummy",
        "rummy",
        "rommy",
        "round",
        "dummy"
      ]
    )

    assert_equal(filtered1.sort, ["tummy", "dummy"].sort)

    m2 = MatchObject.build(matcher:"apple", secret:"puppy")
    filtered2 = m2.filter_list(
      list: [
        "ruppy",
        "puppy",
        "apple",
        "pupty"
      ]
    )
    assert_equal(filtered2.sort, ["puppy", "ruppy", "pupty"].sort)

    m3 = MatchObject.build(matcher:"poppy", secret:"ruppy")

    filtered3 = m3.filter_list(
      list: [
        "ruppy",
        "puppy",
      ]
    )
    assert_equal(filtered3.sort, ["ruppy"].sort)
  end
end