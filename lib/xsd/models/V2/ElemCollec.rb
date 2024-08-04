class ElemCollection
  attr_reader :max_occurrences, :elements, :attrib

  def initialize(max_occurrences = nil, attrib = nil)
    @max_occurrences = max_occurrences
    @attrib = attrib
    @elements = []
  end

  def add_element(element)
    puts "adding element #{element}"
    raise "Max occurrences exceeded" if (!@max_occurrences.nil? and @elements.size >= @max_occurrences )
    @elements << element
  end

  def remove_element(element)
    @elements.delete(element)
  end

  def count
    @elements.size
  end

  def self.xsd_name
    instance = new
    attrib = instance.attrib # done because of the way the attributes are passed
    if attrib[:class].ancestors[1] == BasicType
      attrib[:xsd_path]
    else
      attrib[:class].xsd_name
    end
  end

  def self.from_xml(parser, can_be_empty = false)
    instance = new
    attrib = instance.attrib # done because of the way the attributes are passed

    loop do
      break if parser.current.nil? # Ensure we exit if there's no more elements

      puts "attrib #{attrib[:xsd_path]} current_name #{parser.current.name}"

      if attrib[:class].ancestors.include?(Choice2)
        puts "is choice"
        if attrib[:class].xsd_name.include?(parser.current.name)
          instance.add_element(attrib[:class].from_xml(parser))
        else
          break
        end
      else
        if attrib[:class].ancestors[1] == BasicType
          puts "is basic type"
          if attrib[:xsd_path] == parser.current.name
            instance.add_element(attrib[:class].from_xml(parser, attrib[:xsd_path], can_be_empty))
          else
            break
          end
        else
          puts "is not basic type #{attrib[:class].xsd_name}"
          if attrib[:class].xsd_name.is_a?(Array)
            if attrib[:class].xsd_name.include?(parser.current.name)
              instance.add_element(attrib[:class].from_xml(parser))
            else
              break
            end
          else
            if attrib[:class].xsd_name == parser.current.name
              instance.add_element(attrib[:class].from_xml(parser))
            else
              break
            end
          end
        end
      end

      # Do not move to the next element in the XML
    end

    instance
  end

  def to_s
    @elements.map(&:to_s).join(', ')
  end
end
