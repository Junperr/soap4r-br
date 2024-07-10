require_relative 'basic_type'

class ParsedDateTime < BasicType
  def initialize
    super('DateTime')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
