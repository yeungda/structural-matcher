class StructuralMatcher
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
