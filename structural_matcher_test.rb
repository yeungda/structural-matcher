require 'rubygems'
require 'unindent'

class StructuralMatcherTest

  def assert_equals(expected, actual, context)
    raise Exception.new("#{context}\nexpecting #{expected}, got #{actual}") unless expected == actual
  end

  def expect(expected_data, actual_data, expected_result, expected_description=nil)
    actual_result = StructuralMatcher.match(expected_data, actual_data)
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

StructuralMatcherTest.new.test
