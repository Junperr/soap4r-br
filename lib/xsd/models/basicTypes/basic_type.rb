require 'date'
require 'time'
require 'bigdecimal'

class BasicType
  attr_reader :value

  def initialize(type)
    @type = type
    @value = nil
    @value_str = nil
  end

  def value=(new_value)
    @value = validate(new_value)
    @value_str = new_value
  end

  def self.from_xml(element)
    instance = new('String')
    instance.value = element.content
    instance
  end

  def to_s
    @value_str
  end

  private

  def validate(value)
    case @type
    when 'String'
      check_string(value)
    when 'Integer'
      check_integer(value)
    when 'Float'
      check_float(value)
    when 'Boolean'
      check_boolean(value)
    when 'DateTime'
      check_date_time(value)
    when 'Time'
      check_time(value)
    when 'Date'
      check_date(value)
    when :'BigDecimal'
      check_big_decimal(value)
    else
      raise ArgumentError, "Unsupported type: #{@type}"
    end
  end

  def check_string(value)
    raise ArgumentError, "Invalid String" unless value.is_a?(String)
    value
  end

  def check_integer(value)
    Integer(value) # This will raise an error if the value is not a valid integer
  rescue ArgumentError
    raise ArgumentError, "Invalid Integer"
  end

  def check_float(value)
    Float(value) # This will raise an error if the value is not a valid float
  rescue ArgumentError
    raise ArgumentError, "Invalid Float"
  end

  def check_boolean(value)
    case value
    when 'true', true
      true
    when 'false', false
      false
    else
      raise ArgumentError, "Invalid Boolean"
    end
  end

  def check_date_time(value)
    DateTime.parse(value)
  rescue ArgumentError
    raise ArgumentError, "Invalid DateTime format"
  end

  def check_time(value)
    Time.parse(value)
  rescue ArgumentError
    raise ArgumentError, "Invalid Time format"
  end

  def check_date(value)
    Date.parse(value)
  rescue ArgumentError
    raise ArgumentError, "Invalid Date format"
  end

  def check_big_decimal(value)
    BigDecimal(value)
  rescue ArgumentError
    raise ArgumentError, "Invalid BigDecimal format"
  end

end
