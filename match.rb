require 'rubygems'
require 'unindent'

def match(expectation, actual)
  def match?(expectation, actual)
    if expectation == nil or actual == nil
      expectation == actual
    elsif expectation.class == Hash
      expectation.keys.map {|key|
        expectation_value = expectation[key]
        actual_value = actual[key]
        match?(expectation_value, actual_value)
      }.all? {|match| true == match}
    elsif expectation.class == Array
      (0..expectation.size).to_a.map {|index|
        match?(expectation[index], actual[index])
      }.all? {|match| true == match}
    elsif expectation.respond_to?(:match)
      expectation.match(actual) != nil
    else
      expectation == actual
    end
  end
  description = <<-EOS.unindent
  {
   +:exactmatchstring => ""
   -:exactmatchstring => "exactmatch"
  }
  EOS
  {:matches? => match?(expectation, actual),
   :description => description}
end

class MatcherTest

  def assert_equals(expected, actual, context)
    raise Exception.new("#{context}\nexpecting #{expected}, got #{actual}") unless expected == actual
  end

  def expect(expected_data, actual_data, expected_result, expected_description=nil)
    actual_result = match(expected_data, actual_data)
    context = "when matching #{expected_data} with #{actual_data},"
    assert_equals(expected_result, actual_result[:matches?], context)
    assert_equals(expected_description, actual_result[:description], context) unless expected_description.nil?
  end
  
  def test
    examples = [
      [{}, {}, true, nil],
      [{:exactmatchstring => "exactmatch"}, {:exactmatchstring => "exactmatch"}, true],
      [{:exactmatchstring => ""}, {:exactmatchstring => "exactmatch"}, false,
      <<-EOS.unindent
      {
       +:exactmatchstring => ""
       -:exactmatchstring => "exactmatch"
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
    examples.each {|example|
      expect(example[0], example[1], example[2], example[3])
    }
  end

end
MatcherTest.new.test
