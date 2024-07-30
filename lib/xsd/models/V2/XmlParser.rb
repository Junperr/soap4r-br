require 'nokogiri'

class XMLParser
  def initialize(xml_content)
    @doc = Nokogiri::XML(xml_content)
    @root = @doc.root
    @current = @doc.root
    @stack = []
  end

  # Get the next sibling element
  def next
    return nil unless @current

    child = @current.element_children.first
    if child
      @current = child
      return @current
    end

    sibling = @current.next_element
    if sibling
      @current = sibling
    else
      parent = @current.parent
      # puts "parent: #{parent}"
      while parent && !parent.next_element && parent != @root &&@current != @root
        parent = parent.parent
      end
      @current = parent ? parent.next_element : nil
    end
    @current
  end

  # Get the first child element
  def child
    return nil unless @current

    first_child = @current.element_children.first
    if first_child
      @stack.push(@current)
      @current = first_child
    end
    @current
  end

  # Move back to the parent element
  def up
    return nil if @stack.empty?

    @current = @stack.pop
    @current
  end

  # Get the current element
  def current
    @current
  end

  def root
    @root
  end

end

# Example usage
# xml_content = <<~XML
#   <Data>
#     <OptionA>ValueA</OptionA>
#     <OptionB>ValueB</OptionB>
#     <OptionC>ValueC</OptionC>
#   </Data>
# XML
#
# parser = XMLParser.new(xml_content)
#
# puts "Current: #{parser.current.name}"
# puts "First child: #{parser.child.name}"
# puts "Next sibling: #{parser.next.name}"
# puts "Up to parent: #{parser.up.name}"
# puts "Next sibling: #{parser.next.name}"
