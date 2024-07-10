require_relative 'basic_type'

class ParsedTime < BasicType
  def initialize
    super('Time')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
