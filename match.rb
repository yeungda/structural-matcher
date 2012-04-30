require 'rubygems'
require 'unindent'

class SimpleDataMatcher
  def self.match(expectation, actual)
    match = self.match?(expectation, actual)
    if match
      {:matches? => true}
    else
      {:matches? => false, :description => self.describe(expectation, actual)}
    end
  end

  private

  def self.match?(expectation, actual)
    if expectation == nil or actual == nil
      expectation == actual
    elsif expectation.class == Hash
      expectation.keys.map {|key|
        expectation_value = expectation[key]
        actual_value = actual[key]
        self.match?(expectation_value, actual_value)
      }.all? {|match| true == match}
    elsif expectation.class == Array
      (0..expectation.size).to_a.map {|index|
        self.match?(expectation[index], actual[index])
      }.all? {|match| true == match}
    elsif expectation.respond_to?(:match)
      expectation.match(actual) != nil
    else
      expectation == actual
    end
  end

  def self.describe(expectation, actual)
    if expectation == nil or actual == nil
      ""
    elsif expectation.class == Hash
      pairs = expectation.keys.map {|key|
        expectation_value = expectation[key]
        actual_value = actual[key]
        match = self.match?(expectation_value, actual_value)
        if match
          " #{key.inspect} => #{expectation_value.inspect}"
        else
          "-#{key.inspect} => #{expectation_value.inspect}\n" +
          " +#{key.inspect} => #{actual_value.inspect}"
        end
      }.join("\n  ")
      "{\n #{pairs}\n}"
    elsif expectation.class == Array
      ""
    elsif expectation.respond_to?(:match)
      match = self.match?(expectation, actual)
      if match
        " #{expectation.inspect}"
      else
        "-#{expectation.inspect}\n+#{actual.inspect}"
      end
    else
      match = self.match?(expectation, actual)
      if match
        " #{expectation.inspect}"
      else
        "-#{expectation.inspect}\n+#{actual.inspect}"
      end
    end
  end
end

class MatcherTest

  def assert_equals(expected, actual, context)
    raise Exception.new("#{context}\nexpecting #{expected}, got #{actual}") unless expected == actual
  end

  def expect(expected_data, actual_data, expected_result, expected_description=nil)
    actual_result = SimpleDataMatcher.match(expected_data, actual_data)
    context = "when matching #{expected_data} with #{actual_data},"
    assert_equals(expected_result, actual_result[:matches?], context)
    assert_equals(expected_description.rstrip.unindent, actual_result[:description], context) unless expected_description.nil?
  end
  
  def examples
    [
      ["hello", "goodbye", false,
        <<-EOS
        -"hello"
        +"goodbye"
        EOS
      ],
      [1, 2, false,
        <<-EOS
        -1
        +2
        EOS
      ],
      [/xyz/, "abc", false,
        <<-EOS
        -/xyz/
        +"abc"
        EOS
      ],
      [{}, {}, true, nil],
      [{:exactmatchstring => "exactmatch"}, {:exactmatchstring => "exactmatch"}, true],
      [{:exactmatchstring => ""}, {:exactmatchstring => "exactmatch"}, false,
      <<-EOS
      {
       -:exactmatchstring => ""
       +:exactmatchstring => "exactmatch"
      }
      EOS
      ],
      [{:exactmatchinteger => 1}, {:exactmatchinteger => 1}, true],
      [{:exactmatchinteger => 1}, {:exactmatchinteger => 2}, false],
      [{}, {:anything => 'anything'}, true],
      [{:firstpart => 'something'}, 
       {:firstpart => 'something', :secondpart => 'anything'}, 
       true],
      [{:patternmatchstring => /starts with/},
       {:patternmatchstring => 'starts with something'},
       true],
      [{:nestedmap => {:exactvalue => 'matchmeexactly'}},
       {:nestedmap => {:exactvalue => 'matchmeexactly'}},
       true],
      [{:nestedmap => {:patternmatch => /.*theend/}},
       {:nestedmap => {:patternmatch => 'blah blah blah theend'}},
       true],
      [{:nestedmap => {:exactmatch => 'exact',
                       :patternmatch => /.*theend/}},
       {:nestedmap => {:anythingelse => 'anything',
                       :exactmatch => 'exact',
                       :patternmatch => 'blah blah blah theend'}},
       true],
      [{:nestedmap => {:exactmatch => 'wrongvalue'}},
       {:nestedmap => {:anythingelse => 'anything'}},
       false],
      [{:equalarray => [1,2]},
       {:equalarray => [1,2]},
       true],
      [{:mismatchingarray => [1]},
       {:mismatchingarray => [1,2]},
       false],
      [{:arraywithpatternstring => [/hasthisinit/]},
       {:arraywithpatternstring => ["xxxxx hasthisinit xxxx"]},
       true],
      ["exact","exact", true],
      ["exactmismatch","notexact", false],
      [/pattern/,"blah blah pattern blah blah", true]
    ]
  end

  def test
    examples.each {|example|
      expect(example[0], example[1], example[2], example[3])
    }
  end

end

MatcherTest.new.test
