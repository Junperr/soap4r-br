class SimpleRestriction
  attr_reader :value

  def initialize(enumeration: nil, min_length: nil, max_length: nil, length: nil, pattern: nil)
    @enumeration = enumeration
    @min_length = min_length
    @max_length = max_length
    @length = length
    @pattern = pattern
  end

  def value=(new_value)
    validate(new_value)
    @value = new_value
  end

  private

  def validate(value)
    check_enumeration(value)
    check_length(value)
    check_pattern(value)
  end

  def check_enumeration(value) \
    if @enumeration && !@enumeration.include?(value)
      raise ArgumentError, "Value '#{value}' is not in the enumeration: #{@enumeration.join(', ')}"
    end
  end

  def check_length(value)
    if @min_length && value.length < @min_length
      raise ArgumentError, "Value length #{value.length} is less than minimum length #{@min_length}"
    end
    if @max_length && value.length > @max_length
      raise ArgumentError, "Value length #{value.length} is greater than maximum length #{@max_length}"
    end
    if @length && value.length != @length
      raise ArgumentError, "Value length #{value.length} is not equal to length #{@length}"
    end
  end

  def check_pattern(value)
    if @pattern && value !~ @pattern
      raise ArgumentError, "Value '#{value}' does not match pattern #{@pattern}"
    end
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end

  def to_s
    @value
  end

end

