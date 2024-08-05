class Sequence
  attr_accessor :attributes, :elements

  def initialize(attributes = [])
    @attributes = attributes
    @elements = {}
    validate_attributes
  end

  def attr_sequence(type, value)
    puts "type #{type} value #{value}"
    index = @attributes.index { |attr| attr[:name] == type }
    if index
      puts @attributes[index]
      if @attributes[index][:class].is_a?(Class) && @attributes[index][:class].respond_to?(:new)
        @elements[type] = value
        self.instance_variable_set("@#{safevarname(type)}", value)
      else
        raise ArgumentError, "Invalid Sequence type: #{type}"
      end
    else
      raise ArgumentError, "Invalid Sequence type: #{type}"
    end
  end

  def self.xsd_name
    instance = new
    attributes = instance.attributes
    if attributes[0][:class].ancestors[1] == BasicType
      attributes[0][:xsd_path]
    else
      attributes[0][:class].xsd_name
    end
  end

  def self.from_xml(parser, can_be_empty = false)
    instance = new
    instance.attributes.each do |attrib|
      puts "attrib #{attrib[:xsd_path]} current_name #{parser.current.name}"
      if attrib[:class].ancestors.include?(Choice2)
        puts "is choice"
        if attrib[:class].xsd_name.include?(parser.current.name)
          instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
        end
      else
        if attrib[:class].ancestors[1] == BasicType
          puts "is basic type"
          if attrib[:xsd_path] == parser.current.name
            instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser, attrib[:xsd_path], can_be_empty))
          else
            raise "Current element #{parser.current.name} should be #{attrib[:xsd_path]}"
          end
        else
          puts "is not basic type #{attrib[:class].xsd_name}"
          if attrib[:class].xsd_name.is_a?(Array)
            if attrib[:class].xsd_name.include?(parser.current.name)
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
            else

                raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
              end
          else
            if attrib[:class].xsd_name == parser.current.name
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
            else
              raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
            end
          end

        end
      end
      end
      instance
      # else
      #   raise "Current element #{parser.current.name} should be #{instance.xsd_name}"
      # end

  end

  def validate_attributes
    if @attributes.empty?
      raise ArgumentError, "At least one attribute must be provided"
    end
  end

  def self.shorter_name
    name.split('::').last
  end

  def self.enclosing_class
    name_parts = self.name.split('::')
    if name_parts.length > 1
      parent_class_name = name_parts[0...-1].join('::')
      Object.const_get(parent_class_name)
    else
      nil
    end
  end

  def self.path
    self.enclosing_class.path
  end

  def to_s
    class_name = self.class.shorter_name
    attributes_str = @elements.map { |key, elem| "#{key} : #{elem.to_s}" }.join(', ')
    "#{class_name} : {#{attributes_str}}"
  end

  def uncapitalize(target)
    target.sub(/^([A-Z])/) { $1.downcase }
  end

  def safevarname(name)
    safename = uncapitalize(name.scan(/[a-zA-Z0-9_]+/).join('_'))
    if /\A[a-z]/ !~ safename
      "v_#{safename}"
    else
      safename
    end
  end
end

# Example usage
# attributes = [
#   { type: :type1, value: SomeClass.new },
#   { type: :type2, value: AnotherClass.new }
# ]
#
# sequence = Sequence.new(attributes)
# puts sequence
