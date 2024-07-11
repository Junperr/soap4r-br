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

  def self.from_xml(doc, path)
    element = doc.at_xpath(path)
    return nil unless element
    instance = new('String')
    instance.value = element.content
    instance
  end


  def to_s
    @value_str
  end

  private

  def validate(value)
    # puts "Validating #{value} as #{@type} #{self.class}"
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
    when 'BigDecimal'
      check_big_decimal(value)
    when 'Base64Binary'
      check_base64_binary(value)
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

  def check_base64_binary(value)
    raise ArgumentError, "Invalid base64Binary" unless value.is_a?(String) && value.match?(/\A[A-Za-z0-9+\/=]+\z/)
    value
  end

  def self.enclosing_class
    name_parts = self.name.split('::')
    # Ensure there is at least one parent class
    if name_parts.length > 1
      # Get the parent class name
      parent_class_name = name_parts[0...-1].join('::')
      # Find the class object for the parent class name
      Object.const_get(parent_class_name)
    else
      nil
    end
  end

  def self.path
    self.enclosing_class.path + "/#{self.xsd_name}"
  end

end
