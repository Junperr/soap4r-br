class Choice
  attr_accessor :attributes, :choice

  def initialize(attributes = {})
    @attributes = attributes
    @choice = nil
    @choice_value = nil

    validate_attributes
  end

  def attr_choice(type, value)
    if @attributes.key?(type)
      if @attributes[type].is_a?(Class) && @attributes[type].respond_to?(:new)
        @choice = @attributes[type].new
        @choice.value = value
      else
        @choice = SimpleChoice.new(@attributes[type])
        @choice.value = value
      end
      @choice_value = value
    else
      raise ArgumentError, "Invalid Choice type: #{type}"
    end
  end

  def validate_attributes
    if @attributes.empty?
      raise ArgumentError, "At least one attribute must be provided"
    end
  end

  def handle_choice
    if @choice
      @choice.handle
    else
      raise "No valid choice defined"
    end
  end

  def choice_value
    @choice_value
  end
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

