require 'base64'
require_relative 'basic_type'

class ParsedBase64Binary < BasicType

  def initialize
    super('String') # Treat base64Binary as a String type initially
  end

  def value=(new_value)
    @value = validate(new_value)
    @value_str = new_value
    @decoded_value = Base64.decode64(new_value)
  end

  def decoded_value
    @decoded_value
  end

  def self.from_xml(doc, path)
    element = doc.at_xpath(path)
    return nil unless element
    instance = new
    instance.value = element.content
    instance
  end

  def to_s
    "Base64Binary: #{@value_str}"
  end

end