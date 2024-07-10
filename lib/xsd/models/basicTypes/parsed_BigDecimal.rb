require_relative 'basic_type'

class ParsedBigDecimal < BasicType
  def initialize
    super('BigDecimal')
  end

  def self.from_xml(element)
    instance = new
    instance.value = element.content
    instance
  end
end
