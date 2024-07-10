require_relative 'basic_type'

class ParsedDate < BasicType
  def initialize
    super('Date')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
