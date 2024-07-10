require_relative 'basic_type'

class ParsedFloat < BasicType
  def initialize
    super('Float')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
