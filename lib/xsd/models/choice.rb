class Choice
  attr_accessor :attributes, :choice

  def initialize(attributes = {})
    @attributes = attributes
    @choice = nil
    # @choice_value = nil

    validate_attributes
  end

  def attr_choice(type, value)
    if @attributes.key?(type)
      if @attributes[type].is_a?(Class) && @attributes[type].respond_to?(:new)
        # puts "choosing #{type}"
        # puts "value: #{value} #{value.class}"
        @choice = value
      else
        @choice = SimpleChoice.new(@attributes[type])
        @choice.value = value
      end
      # @choice_value = value.value
    else
      raise ArgumentError, "Invalid Choice type: #{type}"
    end
  end

  def self.from_xml(doc, path)
    instance = new
    instance.attributes.each do |name, attrib|
      puts "choice elem path #{path + "/#{attrib.xsd_name}"}"
      choice_element = doc.at_xpath(path + "/#{attrib.xsd_name}")

      if choice_element
        instance.attr_choice(name, attrib.from_xml(choice_element))
        break
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
    # attributes_str = @attributes.map do |name, value|
    #   value_str = value ? value.to_s : 'nil'  # Convert the value to a string or use 'nil'
    #   "#{name}: #{value_str}"  # Format the string for the attribute
    # end.join(', ')  # Join all attribute strings with commas

    attributes_str = "#{choice.class.name.split('::').last} : #{choice.value.to_s}"

    # Return the class name and attribute
    "#{class_name} : {#{attributes_str}}"
  end

end

class SimpleRestr

  # def handle_choice
  #   if @choice
  #     @choice.handle
  #   else
  #     raise "No valid choice defined"
  #   end
  # end

  # def choice_value
  #   @choice_value
  # end
end

class SimpleChoice
  attr_accessor :value

  def initialize(type)
    @type = type
    @value = nil
  end

  def handle
    case @type
    when DateTime
      puts "Handling DateTime with value: #{@value}"
    when String
      puts "Handling String with value: #{@value}"
    else
      raise "Unsupported type: #{@type}"
    end
  end
end

