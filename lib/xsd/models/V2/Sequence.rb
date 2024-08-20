class Sequence
  attr_accessor :attributes, :elements, :allowed_nil_attributes

  def initialize(attributes = [])
    @attributes = attributes
    # binding.pry
    @attributes.each do |attr|
      self.class.send(:attr_accessor, attr[:name])
      self.instance_variable_set("@#{safevarname(attr[:name])}", attr[:class].new)
    end
    @elements = {}
    @allowed_nil_attributes = []
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
      # puts "attrib #{attrib[:xsd_path]} current_name #{parser.current.name} allowed_nil_attributes #{instance.allowed_nil_attributes} #{instance.allowed_nil_attributes.include?(attrib[:xsd_path])}"
      if attrib[:class].ancestors.include?(Choice2) # is choice
        puts "is choice"
        if attrib[:class].xsd_name.include?(parser.current.name)
          instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
        else
          if !attrib[:class].from_xml(parser) == "skipped" or !instance.allowed_nil_attributes.include?(attrib[:xsd_path]) # can't be skipped
            raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
          end
        end
      else
        if attrib[:class].ancestors[1] == BasicType # is basic type
          puts "is basic type"
          if attrib[:xsd_path] == parser.current.name
            if can_be_empty
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser, attrib[:xsd_path], can_be_empty))
            else
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser, attrib[:xsd_path]))
            end
          else
            if !attrib[:class].from_xml(parser) == "skipped" or !instance.allowed_nil_attributes.include?(attrib[:xsd_path])
              raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
            end
          end
        else # is not basic type (ie a simple type with restrictions)
          puts "is not basic type #{attrib[:class].xsd_name}"
          if attrib[:class].xsd_name.is_a?(Array) # if it's a choice
            if attrib[:class].xsd_name.include?(parser.current.name)
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
            else
              if !attrib[:class].from_xml(parser) == "skipped" or !instance.allowed_nil_attributes.include?(attrib[:xsd_path])
                raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
              end
            end
          else
            if parser.current and attrib[:class].xsd_name == parser.current.name
              instance.attr_sequence(attrib[:name], attrib[:class].from_xml(parser))
            else
              if !instance.allowed_nil_attributes.include?(attrib[:xsd_path]) and !attrib[:class].from_xml(parser) == "skipped"
                raise "Current element #{parser.current.name} should be #{attrib[:class].xsd_name}"
              end
            end
          end

        end
      end
    end
    instance
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
    # get the nested class where it was defined
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

  def to_custom_xml(xml_file)
    # Assuming `@attributes` is a hash or array of attributes
    @attributes.each do |attrib|
      # Convert the attribute name to a safe variable name
      var_name = "@#{safevarname(attrib[:name])}"

      # Fetch the instance variable value dynamically
      elem = self.instance_variable_get(var_name)
      puts "testing variable #{var_name} #{elem}"
      # Ensure the element responds to the method 'to_custom_xml'
      if elem
        puts "to custom xml #{elem.class}"
        to_xml_method = elem.method(:to_custom_xml)
        parameters = to_xml_method.parameters
        if parameters.length >= 2
          xml_file = elem.to_custom_xml(xml_file, attrib[:xsd_path])
        else
          xml_file = elem.to_custom_xml(xml_file)
        end
      end
    end

    xml_file
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