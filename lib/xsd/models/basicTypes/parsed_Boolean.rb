require_relative 'basic_type'

class ParsedBoolean < BasicType
  def initialize
    super('Boolean')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
