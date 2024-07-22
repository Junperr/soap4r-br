# frozen_string_literal: true

require_relative 'basic_type'

class ParsedString < BasicType
  def initialize
    super('String')
  end
  def self.from_xml(doc, path, can_be_empty)
    element = doc.at_xpath(path)
    return nil unless element
    instance = new
    instance.value = element.content
    instance
  end
end
