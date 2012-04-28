def assert_equals(expected, actual)
  throw Exception.new("expecting '#{expected}', got '#{actual}'") unless expected == actual
end

def match(expectation, actual)
  def is_match?(expectation, actual)
    if expectation == nil or actual == nil
      expectation == actual
    elsif expectation.class == Hash
      expectation.keys.map {|key|
        expectation_value = expectation[key]
        actual_value = actual[key]
        is_match?(expectation_value, actual_value)
      }.all? {|match| true == match}
    elsif expectation.class == Array
      (0..expectation.size).to_a.map {|index|
        is_match?(expectation[index], actual[index])
      }.all? {|match| true == match}
    elsif expectation.respond_to?(:match)
      expectation.match(actual) != nil
    else
      expectation == actual
    end
  end
  {:matches? => is_match?(expectation, actual)}
end

def expect(expected_data, actual_data, expected_result, description=nil)
  actual_result = match(expected_data, actual_data)[:matches?]
  error_message = "when matching #{expected_data} with #{actual_data},\nexpecting #{expected_result}, got #{actual_result}"
  raise Exception.new(error_message) unless actual_result == expected_result
end

examples = [
  [{}, {}, true, nil],
  [{:exactmatchstring => "exactmatch"}, {:exactmatchstring => "exactmatch"}, true],
  [{:exactmatchstring => ""}, {:exactmatchstring => "exactmatch"}, false],
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
  expect(example[0], example[1], example[2])
}

