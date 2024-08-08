class Choice2
  attr_accessor :choice, :attributes

  def initialize(attributes = {})
    @attributes = attributes
    @choice = nil
    validate_attributes
  end

  def attr_choice(type, value)
    if @attributes.key?(type)
      if @attributes[type][:class].is_a?(Class) && @attributes[type][:class].respond_to?(:new)
        @choice = value
      else
        raise ArgumentError, "Invalid Choice type: #{type}"
      end
      # @choice_value = value.value
    else
      raise ArgumentError, "Invalid Choice type: #{type}"
    end
  end

  def self.xsd_name
    arr = []
    instance = new
    attributes = instance.attributes
    attributes.keys.each { |key|
      if attributes[key][:class].ancestors.include?(Choice2)
        attributes[key][:class].xsd_name.each { |elem|
          arr << elem
        }
      else

        if attributes[key][:class].ancestors[1] == BasicType
          arr << attributes[key][:xsd_path]
        else
          arr << attributes[key][:class].xsd_name
        end
      end
    }
    arr
  end

  def self.from_xml(parser, canBeEmpty = false)
    instance = new
    if self.xsd_name.include?(parser.current.name)
      instance.attributes.each do |name, attrib|
        # puts "choice elem path #{path + "/#{attrib[:class].xsd_name}"}"

        if attrib[:class].ancestors.include?(Choice2)
          if attrib[:class].xsd_name.include?(parser.current.name)
            instance.attr_choice(name, attrib[:class].from_xml(parser))
            break
          end
        else
          if attrib[:class].ancestors[1] == BasicType
            if attrib[:xsd_path] == parser.current.name
              instance.attr_choice(name, attrib[:class].from_xml(parser))
              break
            end
          else
            if attrib[:class].xsd_name == parser.current.name
              instance.attr_choice(name, attrib[:class].from_xml(parser))
              break
            end
          end

        end
      end
      instance
    else
      if canBeEmpty
        return "skipped"
      end
      raise "Current element #{parser.current.name} should be #{instance.xsd_name}"
    end

  end

  def self.compare_xsd_name(name, elem)
    if elem[:class].ancestors.include?(Choice2)
      self.xsd_path.include?(name)
    else
      return false
    end
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
    # Ensure there is at least one parent class
    if name_parts.length > 1
      # Get the parent class name
      parent_class_name = name_parts[0...-1].join('::')
      # Find the class object for the parent class name
      Object.const_get(parent_class_name)
    else
      nil
    end
  end

  def self.path
    # puts "enclosing_class: #{self.class.enclosing_class}"
    # puts "enclosing_class.class: #{self.class.enclosing_class.class}"
    self.enclosing_class.path
  end

  def to_s
    class_name = self.class.shorter_name # Get the class name
    # Create a string representation of attributes and their values

    attributes_str = "#{choice.class.name.split('::').last} : #{choice.to_s}"

    # Return the class name and attribute
    "#{class_name} : {#{attributes_str}}"
  end

end