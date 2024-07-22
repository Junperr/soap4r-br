# RestrictedBasicType class is a class that take a type
# a soaptype and a restriction map as arguments
# it make sure the value respect the types and the restrictions

class RestrictedBasicType < BasicType
  def initialize(type, soap_type = '', restrictions = {})
    super(type)
    add_restriction(restrictions, soap_type)
  end

  def value=(new_value)
    @value = validate(new_value)
    @value_str = new_value
  end

  def self.from_xml(doc, type, soap_type = '', restrictions = {})
    element = doc.at_xpath(self.path)
    return nil unless element
    instance = new(type, soap_type, restrictions)
    instance.value = element.content
    instance
  end

  # def parse_restrictions(restrictions)
  #   case @type
  #
  #   end
  # end

  def validate(value)
    new_value = super(value)
    check_restrictions(new_value)
  end

  def check_restrictions(value)
    check_enumeration(value)
    check_length(value)
    check_pattern(value)
    check_inclusive(value)
    check_exclusive(value)
    check_total_digits(value)
    check_white_space(value)
  end

  def add_restriction(restrictions, soap_type = '')
    case soap_type
    when 'SOAP::SOAPNonNegativeInteger'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 0, 0].max
    when 'SOAP::SOAPPositiveInteger'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 1, 1].max
    when 'SOAP::SOAPNonPositiveInteger'
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 0, 0].min
    when 'SOAP::SOAPNegativeInteger'
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || -1, -1].min
    when 'SOAP::SOAPInteger'
      # No specific restrictions to add for SOAP::SOAPInteger
    when 'SOAP::SOAPLong'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || -9223372036854775808, -9223372036854775808].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 9223372036854775807, 9223372036854775807].min
    when 'SOAP::SOAPInt'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || -2147483648, -2147483648].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 2147483647, 2147483647].min
    when 'SOAP::SOAPShort'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || -32768, -32768].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 32767, 32767].min
    when 'SOAP::SOAPByte'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || -128, -128].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 127, 127].min
    when 'SOAP::SOAPUnsignedLong'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 0, 0].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 18446744073709551615, 18446744073709551615].min
    when 'SOAP::SOAPUnsignedInt'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 0, 0].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 4294967295, 4294967295].min
    when 'SOAP::SOAPUnsignedShort'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 0, 0].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 65535, 65535].min
    when 'SOAP::SOAPUnsignedByte'
      restrictions[:minInclusive] = [restrictions[:minInclusive] || 0, 0].max
      restrictions[:maxInclusive] = [restrictions[:maxInclusive] || 255, 255].min
    end

    @restrictions = restrictions

  end

  def check_enumeration(value) \
    if @restrictions[:enumeration] && !@restrictions[:enumeration].include?(value)
      raise ArgumentError, "Value '#{value}' is not in the enumeration: #{@restrictions[:enumeration].join(', ')}"
    end
  end

  def check_length(value)
    if @restrictions[:minLength] && value.length < @restrictions[:minLength]
      raise ArgumentError, "Value length #{value.length} is less than minimum length #{@restrictions[:minLength]}"
    end
    if @restrictions[:maxLength] && value.length > @restrictions[:maxLength]
      raise ArgumentError, "Value length #{value.length} is greater than maximum length #{@restrictions[:maxLength]}"
    end
    if @restrictions[:length] && value.length != @restrictions[:length]
      raise ArgumentError, "Value length #{value.length} is not equal to length #{@restrictions[:length]}"
    end
  end

  def check_pattern(value)
  if @restrictions[:pattern]
    patterns = [@restrictions[:pattern]].flatten # Ensure patterns is an array
    pattern_matched = patterns.any? { |pattern| value =~ pattern }
    unless pattern_matched
      raise ArgumentError, "Value '#{value}' does not match any pattern: #{patterns.join(', ')}"
    end
  end
end

  def check_inclusive(value)
    if @restrictions[:minInclusive] && value < @restrictions[:minInclusive]
      raise ArgumentError, "Value #{value} is less than minimum value #{@restrictions[:minInclusive]}"
    end
    if @restrictions[:maxInclusive] && value > @restrictions[:maxInclusive]
      raise ArgumentError, "Value #{value} is greater than maximum value #{@restrictions[:maxInclusive]}"
    end
  end

  def check_exclusive(value)
    if @restrictions[:minExclusive] && value <= @restrictions[:minExclusive]
      raise ArgumentError, "Value #{value} is less than or equal to minimum value #{@restrictions[:minExclusive]}"
    end
    if @restrictions[:maxExclusive] && value >= @restrictions[:maxExclusive]
      raise ArgumentError, "Value #{value} is greater than or equal to maximum value #{@restrictions[:maxExclusive]}"
    end
  end

  def check_total_digits(value)
  value_str = big_decimal_to_s(value)
  # puts "value_str: #{value_str} value: #{value}"

  if @restrictions[:totalDigits] && value_str.gsub('.', '').length > @restrictions[:totalDigits]
    raise ArgumentError, "Value #{value_str} has more than #{@restrictions[:totalDigits]} digits"
  end

  if @restrictions[:fractionDigits] && value_str.include?('.')
    fraction_digits = value_str.split('.').last.length
    if fraction_digits > @restrictions[:fractionDigits]
      raise ArgumentError, "Value #{value_str} has more than #{@restrictions[:fractionDigits]} fraction digits"
    end
  end
end

  def check_white_space(value)
    case @restrictions[:whiteSpace]
    when 'preserve'
      value
    when 'replace'
      value.gsub(/[\t\n\r]/, ' ')
    when 'collapse'
      value.gsub(/[\t\n\r]/, ' ').squeeze(' ').strip
    else
      value
    end
  end

  def big_decimal_to_s(value)
    if @type == 'BigDecimal'
      value.to_s('F')
    else
      value.to_s
    end
  end

  def restrictions
    @restrictions
  end

end
