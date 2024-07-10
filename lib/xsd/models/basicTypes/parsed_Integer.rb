require_relative 'basic_type'

class ParsedInteger < BasicType
  def initialize
    super('Integer')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
