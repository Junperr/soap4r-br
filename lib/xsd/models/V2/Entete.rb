# encoding: UTF-8
require_relative 'all_class'
require_relative 'XmlParser'

# {}EN
#   nM - nM
#   gdhE - ParsedDateTime
#   vREFH - ParsedBoolean
#   vER - VER
class EN

  # SpecificChoice for NErE
  #   nE - NE
  #   rE - rE
  class ChoiceNErE < Choice2

    # inner class for member: NE
    # {}NE
    class NE < RestrictedBasicType
      def self.xsd_name
        "NE"
      end

      def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 10 }, can_be_empty = false)
        super(type, soap_type, restrictions)
      end

      def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 10 }, can_be_empty = false)
        if parser.current.name != self.xsd_name
          if can_be_empty
            nil
          end
          raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
        end
        element = parser.current
        instance = new(type, soap_type, restrictions)
        instance.value = element.content
        instance
      end
    end

    # inner class for member: rE
    # {}rE
    class RE < RestrictedBasicType
      def self.xsd_name
        "rE"
      end

      def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 9 }, can_be_empty = false)
        super(type, soap_type, restrictions)
      end

      def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 9 }, can_be_empty = false)
        if parser.current.name != self.xsd_name
          if can_be_empty
            nil
          end
          raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
        end
        element = parser.current
        instance = new(type, soap_type, restrictions)
        instance.value = element.content
        instance
      end
    end

    attr_accessor :nE
    attr_accessor :rE

    def initialize(can_be_empty = false)
      super(NE: NE, RE: RE)
    end
  end

  # SpecificChoice for NDrD
  #   nD - ND
  #   rD - rD
  class ChoiceNDrD < Choice2

    # inner class for member: ND
    # {}ND
    class ND < RestrictedBasicType
      def self.xsd_name
        "ND"
      end

      def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 10 }, can_be_empty = false)
        super(type, soap_type, restrictions)
      end

      def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 10 }, can_be_empty = false)
        if parser.current.name != self.xsd_name
          if can_be_empty
            nil
          end
          raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
        end
        element = parser.current
        instance = new(type, soap_type, restrictions)
        instance.value = element.content
        instance
      end
    end

    # inner class for member: rD
    # {}rD
    class RD < RestrictedBasicType
      def self.xsd_name
        "rD"
      end

      def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 9 }, can_be_empty = false)
        super(type, soap_type, restrictions)
      end

      def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { maxLength: 9 }, can_be_empty = false)
        if parser.current.name != self.xsd_name
          if can_be_empty
            nil
          end
          raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
        end
        element = parser.current
        instance = new(type, soap_type, restrictions)
        instance.value = element.content
        instance
      end
    end

    attr_accessor :nD
    attr_accessor :rD

    def initialize(can_be_empty = false)
      super(ND: ND, RD: RD)
    end
  end

  # inner class for member: nM
  # {}nM
  class NM < RestrictedBasicType
    def self.xsd_name
      "nM"
    end

    def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { length: 26, pattern: [/\A(((BE|BG|CZ|CH|DK|DE|EE|IE|EL|ES|FR|HR|IT|CY|LV|LT|LU|HU|MT|NL|AT|PL|PT|RO|SI|SK|FI|SE|UK)[0-9]{3}[0-9a-zA-Z| ]{4})|[0-9]{9})([0-9]{4}|[ ]{4})([1-9]|A|B)[0-9a-zA-Z]{12}\z/] }, can_be_empty = false)
      super(type, soap_type, restrictions)
    end

    def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { length: 26, pattern: [/\A(((BE|BG|CZ|CH|DK|DE|EE|IE|EL|ES|FR|HR|IT|CY|LV|LT|LU|HU|MT|NL|AT|PL|PT|RO|SI|SK|FI|SE|UK)[0-9]{3}[0-9a-zA-Z| ]{4})|[0-9]{9})([0-9]{4}|[ ]{4})([1-9]|A|B)[0-9a-zA-Z]{12}\z/] }, can_be_empty = false)
      super( parser, type,  soap_type,  restrictions, can_be_empty)
    end
  end

  # inner class for member: VER
  # {}VER
  class VER < RestrictedBasicType
    def self.xsd_name
      "VER"
    end

    def initialize(type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { length: 3 }, can_be_empty = false)
      super(type, soap_type, restrictions)
    end

    def self.from_xml(parser, type = 'String', soap_type = 'SOAP::SOAPString', restrictions = { length: 3 }, can_be_empty = false)
      if parser.current.name != self.xsd_name
        if can_be_empty
          nil
        end
        raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
      end
      element = parser.current
      instance = new(type, soap_type, restrictions)
      instance.value = element.content
      instance
    end
  end

  attr_accessor :choiceNErE
  attr_accessor :choiceNDrD
  attr_accessor :nM
  attr_accessor :gdhE
  attr_accessor :vREFH
  attr_accessor :vER

  def initialize(choiceNErE = nil, choiceNDrD = nil, nM = nil, gdhE = nil, vREFH = nil, vER = nil, can_be_empty = false)
    @choiceNErE = ChoiceNErE.new
    @choiceNDrD = ChoiceNDrD.new
    @nM = NM.new
    @nM.value = nM if nM
    @gdhE = ParsedDateTime.new
    @gdhE.value = gdhE if gdhE
    @vREFH = ParsedBoolean.new
    @vREFH.value = vREFH if vREFH
    @vER = VER.new
    @vER.value = vER if vER
  end

  def self.path()
    "//#{self.xsd_name}"
  end

  def self.xsd_name()
    "EN"
  end

  def self.from_xml(xml, path = nil, can_be_empty = false)
    parser = XMLParser.new(xml)
    if parser.current.name != self.xsd_name and !can_be_empty
      raise "Current element #{parser.current.name} should be a #{self.xsd_name}"
    end
    parser.next
    instance = new
    instance.choiceNErE = ChoiceNErE.from_xml(parser, false || can_be_empty)
    instance.choiceNDrD = ChoiceNDrD.from_xml(parser, false || can_be_empty)
    instance.nM = NM.from_xml(parser)
    instance.gdhE = ParsedDateTime.from_xml(parser, 'GdhE', false || can_be_empty)
    instance.vREFH = ParsedBoolean.from_xml(parser, 'VREFH', false || can_be_empty)
    instance.vER = VER.from_xml(parser)
    instance
  end

  def to_s
    attributes = self.instance_variables.map do |var|
      value = self.instance_variable_get(var)
      if value.is_a?(Array)
        value_str = value.map(&:to_s).join(', ')
        "#{var}: [#{value_str}]"
      else
        "#{var}: #{value}"
      end
    end
    "#{self.class.name}: {#{attributes.join(", ")}}"
  end
end
