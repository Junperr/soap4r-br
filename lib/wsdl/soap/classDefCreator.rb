# encoding: UTF-8
# WSDL4R - Creating class definition from WSDL
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.

require 'wsdl/data'
require 'wsdl/soap/classDefCreatorSupport'
require 'xsd/codegen'
require 'set'

module WSDL
  module SOAP

    class ClassDefCreator
      include ClassDefCreatorSupport
      include XSD::CodeGen

      def initialize(definitions, name_creator, modulepath = nil)
        @definitions = definitions
        @name_creator = name_creator
        @modulepath = modulepath
        @elements = definitions.collect_elements
        @elements.uniq!
        @attributes = definitions.collect_attributes
        @attributes.uniq!
        @simpletypes = definitions.collect_simpletypes
        @simpletypes.uniq!
        @complextypes = definitions.collect_complextypes
        @complextypes.uniq!
        @modelgroups = definitions.collect_modelgroups
        @modelgroups.uniq!
        @faulttypes = nil
        if definitions.respond_to?(:collect_faulttypes)
          @faulttypes = definitions.collect_faulttypes
        end
        @defined_const = {}
      end

      def dump(type = nil)
        puts "\n\nDumping class definition..."
        puts "group: #{@modelgroups.inspect}"
        puts "simpletype: #{@simpletypes.inspect}"
        puts "complextypes: #{@complextypes.inspect}"
        puts "elements: #{@elements.inspect}"
        puts "attributes: #{@attributes.inspect}"

        result = "require_relative 'all_class'\n" # any imports you want for your class
        # cannot use @modulepath because of multiple classes
        if @modulepath
          result << "\n"
          result << modulepath_split(@modulepath).collect { |ele| "module #{ele}" }.join("; ")
          result << "\n\n"
        end
        str = dump_group(type)
        unless str.empty?
          result << "\n" unless result.empty?
          result << str
        end
        str = dump_complextype(type)
        unless str.empty?
          result << "\n" unless result.empty?
          result << str
        end
        str = dump_simpletype(type)
        unless str.empty?
          result << "\n" unless result.empty?
          result << str
        end
        str = dump_element(type)
        unless str.empty?
          result << "\n" unless result.empty?
          result << str
        end
        str = dump_attribute(type)
        unless str.empty?
          result << "\n" unless result.empty?
          result << str
        end
        if @modulepath
          result << "\n\n"
          result << modulepath_split(@modulepath).collect { |ele| "end" }.join("; ")
          result << "\n"
        end
        result
      end

      private

      def dump_element(target = nil)
        @elements.collect { |ele|
          next if @complextypes[ele.name]
          next if target and target != ele.name
          c = create_elementdef(@modulepath, ele)
          c ? c.dump : nil
        }.compact.join("\n")
      end

      def dump_attribute(target = nil)
        @attributes.collect { |attribute|
          next if target and target != attribute.name
          if attribute.local_simpletype
            c = create_simpletypedef(@modulepath, attribute.name, attribute.local_simpletype)
          end
          c ? c.dump : nil
        }.compact.join("\n")
      end

      def dump_simpletype(target = nil)
        @simpletypes.collect { |type|
          next if target and target != type.name
          puts "Creating simple type: #{type.name}"
          c = create_simpletypedef(@modulepath, type.name, type)
          c ? c.dump : nil
        }.compact.join("\n")
      end

      def dump_complextype(target = nil)
        definitions = sort_dependency(@complextypes).collect { |type|
          next if target and target != type.name
          c = create_complextypedef(@modulepath, type.name, type)
          c ? c.dump : nil
        }.compact.join("\n")
      end

      def dump_group(target = nil)
        definitions = @modelgroups.collect { |group|
          # TODO: not dumped for now but may be useful in the future
        }.compact.join("\n")
      end

      def create_elementdef(mpath, ele)
        puts "Creating element: #{ele.name} #{ele.type} #{ele.local_complextype} #{ele.local_simpletype}"
        qualified = (ele.elementform == 'qualified')
        if ele.local_complextype
          puts "Creating complex type: #{ele.name}"
          puts "ele.chid.size: #{ele.local_complextype.elements.size}"
          puts "ele.content: #{ele.local_complextype.content}"
          create_complextypedef(mpath, ele.name, ele.local_complextype, qualified)
        elsif ele.local_simpletype
          puts "Creating simple type: #{ele.name}"
          create_simpletypedef(mpath, ele.name, ele.local_simpletype, qualified)
        elsif ele.name != ele.type
          puts "Creating simple class for : #{ele.name}"
          create_refTypeDef(mpath, ele)
        elsif ele.empty?
          puts "Creating simple class: #{ele.name}"
          create_simpleclassdef(mpath, ele.name, nil)
        else
          # ignores type only element
          nil
        end
      end

      def create_simpletypedef(mpath, qname, simpletype, qualified = false, can_be_empty = false)
        puts "check2 empty for #{qname} #{can_be_empty}"
        if simpletype.restriction
          create_simpletypedef_restriction(mpath, qname, simpletype, qualified, can_be_empty)
        elsif simpletype.list
          create_simpletypedef_list(mpath, qname, simpletype, qualified)
        elsif simpletype.union
          create_simpletypedef_union(mpath, qname, simpletype, qualified)
        else
          raise RuntimeError.new("unknown kind of simpletype: #{simpletype}")
        end
      end

      def newtype?
        # code here
      end

      def create_simpletypedef_restriction(mpath, qname, typedef, qualified, can_be_empty = false)
        puts "check3 empty for #{qname} #{can_be_empty}"

        restriction = typedef.restriction
        puts "restriction: #{typedef.restriction} #{typedef.restriction.pattern}"
        puts "type.base: #{basetype_class(typedef.base)}"
        puts "soapbase : #{SoapToRubyMap[basetype_class(typedef.base).to_s]}"
        soaptype = basetype_class(typedef.base)
        newtype = SoapToRubyMap[soaptype.to_s]
        unless restriction.enumeration? || restriction.min_length? || restriction.max_length? || restriction.pattern? ||
          restriction.length? || restriction.min_inclusive? || restriction.max_inclusive? || restriction.min_exclusive? ||
          restriction.max_exclusive? || restriction.total_digits? || restriction.fraction_digits? || restriction.white_space? ||
          !newtype.nil?
          # has no restriction
          return nil
        end
        classname = mapped_class_basename(qname, mpath)
        puts "Creating simple type: #{qname} with classname #{classname}"
        c = ClassDef.new(classname, 'RestrictedBasicType')
        c.comment = "#{qname}"
        c.def_method('self.xsd_name') do
          "\"#{qname.to_s.slice(2..-1)}\""
        end
        restrictions = define_string_restriction(restriction)

        c.def_method('initialize', "type = \'#{newtype.to_s.slice(6..-1)}\', soap_type = \'#{soaptype}\', restrictions = #{restrictions}, can_be_empty = #{can_be_empty}") do
          "super(type, soap_type, restrictions)"
        end
        c.def_method('self.from_xml', "parser, type = \'#{newtype.to_s.slice(6..-1)}\', soap_type = \'#{soaptype}\', restrictions = #{restrictions}, can_be_empty = #{can_be_empty}") do
          "super( parser, type,  soap_type,  restrictions, can_be_empty)"
        end
        c
      end

      def create_simpletypedef_list(mpath, qname, typedef, qualified)
        list = typedef.list
        classname = mapped_class_basename(qname, mpath)
        c = ClassDef.new(classname, '::Array')
        c.comment = "#{qname}"
        if simpletype = list.local_simpletype
          if simpletype.restriction.nil?
            raise RuntimeError.new(
              "unknown kind of simpletype: #{simpletype}")
          end
          define_stringenum_restriction(c, simpletype.restriction.enumeration)
          c.comment << "\n  contains list of #{classname}::*"
        elsif list.itemtype
          c.comment << "\n  contains list of #{mapped_class_basename(list.itemtype, mpath)}::*"
        else
          raise RuntimeError.new("unknown kind of list: #{list}")
        end
        c
      end

      def create_simpletypedef_union(mpath, qname, typedef, qualified)
        union = typedef.union
        classname = mapped_class_basename(qname, mpath)
        c = ClassDef.new(classname, '::String')
        c.comment = "#{qname}"
        if union.member_types
          # fixme
          c.comment << "\n any of #{union.member_types}"
        end
        c
      end

      def define_stringenum_restriction(c, enumeration)
        const = {}
        enumeration.each do |value|
          constname = safeconstname(value)
          const[constname] ||= 0
          if (const[constname] += 1) > 1
            constname += "_#{const[constname]}"
          end
          c.def_const(constname, ndq(value))
        end
      end

      def define_string_restriction(restriction)
        restrictions = {
          enumeration: restriction.enumeration? ? "[#{restriction.enumeration.map { |e| "\"#{e}\"" }.join(', ')}]" : nil,
          minLength: restriction.min_length? ? restriction.minlength : nil,
          maxLength: restriction.max_length? ? restriction.maxlength : nil,
          length: restriction.length? ? restriction.length : nil,
          # Initialize pattern as nil, will be updated if patterns are present
          pattern: nil,
          minInclusive: restriction.min_inclusive? ? restriction.min_inclusive : nil,
          maxInclusive: restriction.max_inclusive? ? restriction.max_inclusive : nil,
          minExclusive: restriction.min_exclusive? ? restriction.min_exclusive : nil,
          maxExclusive: restriction.max_exclusive? ? restriction.max_exclusive : nil,
          totalDigits: restriction.total_digits? ? restriction.total_digits : nil,
          fractionDigits: restriction.fraction_digits? ? restriction.fraction_digits : nil,
          whiteSpace: restriction.white_space? ? "'#{restriction.white_space}'" : nil
        }

        # Check if pattern is present and is an array
        if restriction.pattern? && restriction.pattern.is_a?(Array)
          pattern_strings = restriction.pattern.map do |pattern|
            "/#{pattern.source}/"
          end
          restrictions[:pattern] = "[#{pattern_strings.join(', ')}]"
        end

        restrictions

        "{#{restrictions.map { |key, value| "#{key}: #{value}" unless value.nil? }.compact.join(', ')}}"
      end

      def define_classenum_restriction(c, classname, enumeration)
        const = {}
        enumeration.each do |value|
          constname = safeconstname(value)
          const[constname] ||= 0
          if (const[constname] += 1) > 1
            constname += "_#{const[constname]}"
          end
          c.def_const(constname, "new(#{ndq(value)})")
        end
      end

      def create_simpleclassdef(mpath, qname, type_or_element)
        classname = mapped_class_basename(qname, mpath)
        c = ClassDef.new(classname, '::String')
        c.comment = "#{qname}"
        init_lines = []
        if type_or_element and !type_or_element.attributes.empty?
          define_attribute(c, type_or_element.attributes)
          init_lines << "@__xmlattr = {}"
        end
        c.def_method('initialize', '*arg') do
          "super\n" + init_lines.join("\n")
        end
        c
      end

      def create_elem_collec(mpath, qname, element)
        puts "Creating element collection: #{qname} with element #{element}"
        case element
        when XMLSchema::Element
          elem_attrib = get_element_attrib(mpath, element, true)
          c = ClassDef.new('ElemC' + elem_attrib[:name], 'ElemCollection')
          c.comment = "element collection for #{qname}"
          puts "Creating element collection: #{qname}"
          c.def_method('initialize', "max_occ = #{element.maxoccurs || 'nil'}") do
            "super(max_occ, #{init_line_elemC(elem_attrib)})"
          end
        when WSDL::XMLSchema::Sequence
          elem_attrib = get_element_attrib(mpath, element, true)
          c = ClassDef.new('ElemC' + elem_attrib[:name], 'ElemCollection')
          c.comment = "element collection for #{qname}"
          puts "Creating sequence collection: #{qname}"
          c.def_method('initialize', "max_occ = #{element.maxoccurs || 'nil'}") do
            "super(max_occ, #{init_line_elemC(elem_attrib)})"
          end
        when WSDL::XMLSchema::Choice
          elem_attrib = get_element_attrib(mpath, element, true)
          c = ClassDef.new('ElemC' + elem_attrib[:name], 'ElemCollection')
          c.comment = "element collection for #{qname}"
          puts "Creating choice collection: #{qname}"
          c.def_method('initialize', "max_occ = #{element.maxoccurs || 'nil'}") do
            "super(max_occ, #{init_line_elemC(elem_attrib)})"
          end
        else
          raise RuntimeError.new("unknown kind of element: #{element}")
        end
        c
      end

      def create_complextypedef(mpath, qname, type, qualified = false)
        puts "Creating complex type: #{qname} #{type.compoundtype}"
        case type.compoundtype
        when :TYPE_STRUCT, :TYPE_EMPTY, :TYPE_ARRAY
          create_structdef(mpath, qname, type, qualified)
          # when :TYPE_ARRAY
          #   create_arraydef(mpath, qname, type)
        when :TYPE_SIMPLE
          create_simpleclassdef(mpath, qname, type)
        when :TYPE_MAP
          # mapped as a general Hash
          nil
        else
          raise RuntimeError.new(
            "unknown kind of complexContent: #{type.compoundtype}")
        end
      end

      def create_structdef(mpath, qname, typedef, qualified = false)
        classname = mapped_class_basename(qname, mpath)
        baseclassname = nil
        if typedef.complexcontent
          puts "typedef.complexcontent.base: #{typedef.complexcontent.base}"
          if base = typedef.complexcontent.base
            # :TYPE_ARRAY must not be derived (#424)
            basedef = @complextypes[base]
            puts "basedef: #{basedef}"
            if basedef and basedef.compoundtype != :TYPE_ARRAY
              # baseclass should be a toplevel complexType
              baseclassname = mapped_class_basename(base, @modulepath)
            end
          end
        end
        if @faulttypes and @faulttypes.index(qname)
          c = ClassDef.new(classname, '::StandardError')
        else
          c = ClassDef.new(classname, baseclassname)
          puts "typedef.content: #{typedef.content}"
          puts "class name: #{classname} #{baseclassname}"
        end
        c.comment = "#{qname}"
        c.comment << "\nabstract" if typedef.abstract
        # puts "\nc1: #{c.dump}\n"
        parentmodule = mapped_class_name(qname, mpath)
        puts "parentmodule: #{parentmodule}"
        # define all elements and attributes inside itself
        init_lines, init_params, skip_params, from_xml_lines, to_xml_lines =
          parse_elements(c, typedef.elements, qname.namespace, parentmodule)
        init_params << "can_be_empty = false"
        # puts "init_lines: #{init_lines}"
        # puts "init_params: #{init_params}"
        # puts "skip_params: #{skip_params}"
        # puts "from_xml_lines: #{from_xml_lines}"
        # puts "to_xml_lines: #{to_xml_lines}"
        # puts "\nc2: #{c.dump}\n"
        if !skip_params.empty?
          c.def_attr('allowed_nil_attributes', true, 'allowed_nil_attributes')
        end
        unless typedef.attributes.empty?
          define_attribute(c, typedef.attributes)
          init_lines << "@__xmlattr = {}"
        end
        # handle initialize method
        c.def_method('initialize', *init_params) do
          unless skip_params.empty?
            init_lines << "allowed_nil_attributes = #{skip_params}"
          end
          init_lines.join("\n")

        end
        # for min_occur = 0
        #     puts "skip_params before method: #{skip_params}"
        #     unless skip_params.empty?
        #       c.def_method('any_nil_or_empty?', *format_skip_element(skip_params)) do
        #         "instance_variables.any? do |var|
        #   # Skip the attribute if it's allowed to be nil or empty
        #   next if allowed_nil_attributes.include?(var[1..].to_sym)
        #
        #   value = instance_variable_get(var)
        #   if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        #     raise ArgumentError, \"Attribute '\#{var[1..]}' cannot be nil or empty\"
        #   end
        # end"
        #       end
        #     end

        c.def_method('self.path', '') do
          "\"//\#{self.xsd_name}\""
        end

        c.def_method('self.xsd_name', '') do
          "\"#{qname.to_s.slice(2..-1)}\""
        end

        c.def_method('self.from_xml', 'xml, path=nil, can_be_empty = false') do
          "if xml.is_a?(XMLParser)
            parser = xml
          else
            parser = XMLParser.new(xml)
          end
    if !can_be_empty
      if parser.current.nil?
        raise \"Reached end of xml\"
      elsif parser.current.name != self.xsd_name
        raise \"Current element \#{parser.current.name} should be a \#{self.xsd_name}\"
      end
    end
    parser.next
    instance = new\n" + from_xml_lines.join("\n") + "\ninstance"
        end
        c.def_method('to_s') do
          "attributes = self.instance_variables.map do |var|
      value = self.instance_variable_get(var)
      if value.is_a?(Array)
        value_str = value.map(&:to_s).join(', ')
        \"\#{var}: [\#{value_str}]\"
      else
        \"\#{var}: \#{value}\"
      end
    end
    \"\#{self.class.name}: {\#{attributes.join(\", \")}}\""
        end

        c.def_method('to_custom_xml', 'xml_file') do
          # "bonus = ''\n" +
          #   "unless xml_file == ''\n" +
          #   " bonus = \"\\n\"\n" +
          #   "end\n" +
            "xml_inside = ''\n" +
            to_xml_lines.join("\n") + "\n" +
            "if xml_inside != ''\n" +
            " xml_file += \"<\#{self.class.xsd_name}>\"\n" +
            " xml_file += xml_inside\n" +
            " xml_file += \"\</\#{self.class.xsd_name}>\"\n" +
            "end\n" +
            "xml_file"
        end

        # puts "\nc3: #{c.dump}\n"
        c
      end

      def parse_elements(c, elements, base_namespace, mpath, as_array = false)
        init_lines = []
        init_params = []
        skip_params = []
        from_xml_lines = []
        to_xml_lines = []
        any = false
        elements.each do |element|

          case element
          when XMLSchema::Any
            # only 1 <any/> is allowed for now.
            raise RuntimeError.new("duplicated 'any'") if any
            any = true
            attrname = '__xmlele_any'
            c.def_attr(attrname, false, attrname)
            c.def_method('set_any', 'elements') do
              '@__xmlele_any = elements'
            end
            init_lines << "@__xmlele_any = nil"
          when XMLSchema::Element
            puts "\nElement here: #{element.name} #{element.type} #{element.local_complextype} #{element.local_simpletype}"
            if element.as_array?
              cElemCollec = create_elem_collec(mpath, element.name, element)
              puts "cElemCollec: #{cElemCollec.dump}"
            end #  if there is more than 1 occurence we make a element collection

            next if element.ref == SchemaName
            if cElemCollec # to write inside the element collecction
              newC = cElemCollec
              c.def_attr(safemethodname(newC.name), true, safevarname(newC.name))
              c.comment << "\n  #{safemethodname(newC.name)} - #{create_type_name(@modulepath, element) || '(any)'}"
              name = name_element(element, true).name
            else
              newC = c
              name = name_element(element).name
            end
            typebase = @modulepath

            if element.anonymous_type?
              puts "element is anonymous"
              inner = create_elementdef(mpath, element)
              if inner.nil?
                puts "element : #{element.inspect} was not defined"
                next
              end
              unless as_array
                inner.comment = "inner class for member: #{name}\n" + inner.comment
              end
              newC.innermodule << inner
              typebase = mpath
            end
            attrname = safemethodname(name)
            varname = safevarname(name)
            newC.def_attr(attrname, true, varname)
            can_be_empty = false
            if element.minoccurs == 0
              skip_params << "#{name_element(element).name}"
              can_be_empty = true
            end
            inner2 = check_element(element, can_be_empty)

            if inner2 # element is a simple type that we redefine
              elemClass = mapped_class_basename(element.name, @modulepath)
              init_lines << "@#{varname} = #{elemClass}.new\n@#{varname}.value = #{varname} if #{varname}"
              from_xml_lines << "instance.#{varname} = #{elemClass}.from_xml(parser, can_be_empty:#{can_be_empty})"
              to_xml_lines << "xml_inside = @#{varname}.to_custom_xml(xml_inside)"
              init_params << "#{varname} = nil"
              inner2.comment = "inner class for member: #{name}\n" + inner2.comment
              newC.innermodule << inner2
            elsif !element.type.nil? and element.name != element.type
              puts "element is a ref"
              newC.innermodule << create_refTypeDef(mpath, element)
            else
              # is a basic type
              typename = create_type_name(typebase, element) # get the type of the element

              init_lines << "@#{varname} = #{typename}.new"
              init_lines << "@#{varname}.value = #{varname} if #{varname}"

              from_xml_lines << "instance.#{varname} = #{typename}.from_xml(parser,'#{name}',#{can_be_empty} || can_be_empty)"
              to_xml_lines << "xml_inside = @#{varname}.to_custom_xml(xml_inside)"

              init_params << "#{varname} = nil"
            end

            if cElemCollec or !element.as_array?
              newC.comment << "\n  #{attrname} - #{create_type_name(mpath, element, true) || '(any)'}"
            else
              newC.comment << "\n  #{attrname} - #{create_type_name(mpath, element) || '(any)'}"
            end

            if cElemCollec
              c.innermodule << newC
            end
            # puts "type name is #{create_type_name(typebase, element)}"
          when WSDL::XMLSchema::Sequence
            puts "\nSequence here with size #{element.elements.size}"

            if element.as_array?
              cElemCollec = create_elem_collec(mpath, XSD::QName.new, element)
              puts "cElemCollec: #{cElemCollec.dump}"
            end #  if there is more than 1 occurence we make a element collection

            if cElemCollec # to write inside the element collecction
              newC = cElemCollec
              c.def_attr(safemethodname(newC.name), true, safevarname(newC.name))
              puts "newC name is #{newC.name}"
              c.comment << "\n  #{safemethodname(newC.name)} - #{capitalize(safemethodname(newC.name))}"
            else
              newC = c
            end

            elementNames, namecomplement = create_name_complement(mpath, element)

            attrname = 'sequence' + namecomplement
            can_be_empty = false
            if element.minoccurs == 0
              skip_params << "#{name_element(element).name}"
              can_be_empty = true
            end

            newC.def_attr(attrname, true)
            if cElemCollec or !element.as_array?
              newC.comment << "\n  #{attrname} - #{'Sequence' + namecomplement || '(any)'}"
            else
              newC.comment << "\n  #{attrname} - #{'ElemCSequence' + namecomplement || '(any)'}"
            end

            cSeq = ClassDef.new('Sequence' + namecomplement, 'Sequence')
            cSeq.comment = "SpecificSequence for #{namecomplement}"
            puts "cSeq : #{cSeq.dump}"
            child_init_lines, child_init_params, child_skip_params, child_from_xml_lines, child_to_xml_lines =
              parse_elements(cSeq, element.elements, base_namespace, mpath + "::#{'Sequence' + namecomplement}", as_array)
            if !child_skip_params.empty?
              c.def_attr('allowed_nil_attributes', true, 'allowed_nil_attributes')
            end
            init_lines << "@#{attrname} = #{cSeq.name}.new"
            init_params << "#{attrname} = nil"
            from_xml_lines << "instance.#{attrname} = #{cSeq.name}.from_xml(parser,#{can_be_empty} || can_be_empty)"
            to_xml_lines << "xml_inside = @#{attrname}.to_custom_xml(xml_inside)"

            cSeq.def_method('initialize', "can_be_empty = false") do
              lines = ["super(#{init_line_sequence(elementNames)})"]
              lines << "@allowed_nil_attributes = #{child_skip_params}" unless child_skip_params.empty?
              lines.join("\n")
            end

            newC.innermodule << cSeq
            if cElemCollec
              c.innermodule << newC
            end
          when WSDL::XMLSchema::Choice
            puts "\nChoice here with size #{element.elements.size}" # puts all element of element.elements

            if element.as_array?
              cElemCollec = create_elem_collec(mpath, XSD::QName.new, element)
              puts "cElemCollec: #{cElemCollec.dump}"
            end #  if there is more than 1 occurence we make a element collection

            if cElemCollec # to write inside the element collecction
              newC = cElemCollec
              c.def_attr(safemethodname(newC.name), true, safevarname(newC.name))
              puts "newC name is #{newC.name}"

              c.comment << "\n  #{safemethodname(newC.name)} - #{capitalize(safemethodname(newC.name))}"
            else
              newC = c
            end

            elementNames, namecomplement = create_name_complement(mpath, element)

            attrname = 'choice' + namecomplement
            can_be_empty = false
            if element.minoccurs == 0
              skip_params << "#{name_element(element).name}"
              can_be_empty = true
            end

            newC.def_attr(attrname, true)
            if cElemCollec or !element.as_array?
              puts "adding comment to #{newC.name} with #{attrname} and #{'Choice' + namecomplement || '(any)'}"
              newC.comment << "\n  #{attrname} - #{'Choice' + namecomplement || '(any)'}"
            else
              puts "adding comment to #{newC.name} with #{attrname} and #{'ElemCChoice' + namecomplement || '(any)'}"
              newC.comment << "\n  #{attrname} - #{'ElemCChoice' + namecomplement || '(any)'}"
            end
            cChoice = ClassDef.new('Choice' + namecomplement, 'Choice2')
            cChoice.comment = "SpecificChoice for #{namecomplement}"
            puts "cChoice : #{cChoice.dump}"
            child_init_lines, child_init_params, child_skip_params, child_from_xml_lines, child_to_xml_lines =
              parse_elements(cChoice, element.elements, base_namespace, mpath + "::#{'Choice' + namecomplement}", as_array)
            # puts "child_init_lines: #{child_init_lines}"
            # puts "child_init_params: #{child_init_params}"
            # puts "child_skip_params: #{child_skip_params}"
            # puts "child_from_xml_lines: #{child_from_xml_lines}"
            if cElemCollec
              newattrb, newclass = safemethodname(newC.name), capitalize(safemethodname(newC.name))
              init_lines << "@#{newattrb} = #{newclass}.new"
              init_params << "#{newattrb} = nil"
              from_xml_lines << "instance.#{newattrb} = #{newclass}.from_xml(parser,#{can_be_empty} || can_be_empty)"
              to_xml_lines << "xml_inside = @#{newattrb}.to_custom_xml(xml_inside)"
            else
              init_lines << "@#{attrname} = #{cChoice.name}.new"
              init_params << "#{attrname} = nil"
              from_xml_lines << "instance.#{attrname} = #{cChoice.name}.from_xml(parser,#{can_be_empty} || can_be_empty)"
              to_xml_lines << "xml_inside = @#{attrname}.to_custom_xml(xml_inside)"
            end
            # puts "added xml line to #{from_xml_lines}"
            # init_lines.concat(child_init_lines)
            # init_params.concat(child_init_params)

            # puts "cChoice 1: #{cChoice.dump}"
            # puts "hey #{elementNames}"
            cChoice.def_method('initialize', "can_be_empty = false") do
              lines = "super(#{init_line_choice(elementNames)})"
              lines

            end

            # puts "cChoice 2: #{cChoice.dump}"

            newC.innermodule << cChoice
            if cElemCollec
              c.innermodule << newC
            end

          when WSDL::XMLSchema::Group
            if element.content.nil?
              warn("no group definition found: #{element}")
              next
            end
            child_init_lines, child_init_params, child_skip_params, child_from_xml_lines, child_to_xml_lines =
              parse_elements(c, element.content.elements, base_namespace, mpath, as_array)
            init_lines.concat(child_init_lines)
            init_params.concat(child_init_params)
            skip_params.concat(child_skip_params)
            from_xml_lines.concat(child_from_xml_lines)
            to_xml_lines.concat(child_to_xml_lines)
          else
            puts "element #{element} is not element"
            puts "c is #{c} base_namespace is #{base_namespace} mpath is #{mpath} as_array is #{as_array}"
            puts "inspect: #{element.content}"
            raise RuntimeError.new("unknown type: #{element}")
          end
        end

        [init_lines, init_params, skip_params, from_xml_lines, to_xml_lines]
      end

      def check_element(element, can_be_empty = false)
        puts "check1 empty for #{element.name} #{can_be_empty} #{element.local_simpletype}"
        if element.local_simpletype
          puts "check1.1 empty for #{element.name} #{can_be_empty}"
          c = create_simpletypedef(@modulepath, element.name, element.local_simpletype, false, can_be_empty)
          puts "check1.2 empty change for #{element.name} #{can_be_empty}"
          c
          # elsif element.local_complextype
        end
      end

      def create_name_complement(mpath, element)
        # return an array of attribute ()
        elementNames = []
        namecomplement = ""
        element.elements.each do |e|
          qname = name_element(e)
          namecomplement += qname.name
          classname = mapped_class_basename(qname, "")
          puts "element data  classname: #{classname} name: #{qname.name} element: #{e}"
          if e.respond_to?(:name) and !(e.respond_to?(:local_simpletype) && e.local_simpletype) and element_basetype(e, false)
            # is a basic type
            typename = create_type_name(mpath, e)
            elementNames << { name: classname, class: typename, xsd_path: qname.name }
          else
            elementNames << { name: classname, class: classname, xsd_path: qname.name }
          end
        end
        return elementNames, namecomplement
      end

      def get_element_attrib(mpath, element, no_prefix = false)
        classname = mapped_class_basename(name_element(element, no_prefix), "")
        puts "attrib data  classname: #{classname} name: #{name_element(element, no_prefix)} element: #{element}"
        if element.respond_to?(:name) and !(element.respond_to?(:local_simpletype) && element.local_simpletype) and element_basetype(element, false)
          typename = create_type_name(mpath, element)
          { name: classname, class: typename, xsd_path: name_element(element, no_prefix).name }
        else
          { name: classname, class: classname, xsd_path: name_element(element, no_prefix).name }
        end

        # attrib
      end

      def create_refTypeDef(mpath, element)
        puts "Creating refTypeDef: #{element.name} #{element.type}"
        extendClass = mapped_class_basename(element.type, "")
        className = mapped_class_basename(element.name, "")
        c = ClassDef.new(className, "::#{extendClass}")
        c.def_method('self.xsd_name') do
          "'#{mapped_class_basename(element.name, mpath)}'"
        end
        c
      end

      def define_attribute(c, attributes)
        const = {}
        unless attributes.empty?
          c.def_method("__xmlattr") do
            <<-__EOD__
          @__xmlattr ||= {}
            __EOD__
          end
        end
        attributes.each do |attribute|
          name = name_attribute(attribute)
          methodname = safemethodname('xmlattr_' + name.name)
          constname = 'Attr' + safeconstname(name.name)
          const[constname] ||= 0
          if (const[constname] += 1) > 1
            constname += "_#{const[constname]}"
          end
          c.def_const(constname, dqname(name))
          c.def_method(methodname) do
            <<-__EOD__
          __xmlattr[#{constname}]
            __EOD__
          end
          c.def_method(methodname + '=', 'value') do
            <<-__EOD__
          __xmlattr[#{constname}] = value
            __EOD__
          end
          c.comment << "\n  #{methodname} - #{attribute_basetype(attribute) || '(any)'}"
        end
      end

      def create_arraydef(mpath, qname, typedef)
        classname = mapped_class_basename(qname, mpath)
        c = ClassDef.new(classname, '::Array')
        c.comment = "#{qname}"
        parentmodule = mapped_class_name(qname, mpath)
        parse_elements(c, typedef.elements, qname.namespace, parentmodule, true)
        c
      end

      def sort_dependency(types)
        dep = {}
        root = []
        types.each do |type|
          if type.complexcontent and (base = type.complexcontent.base)
            dep[base] ||= []
            dep[base] << type
          else
            root << type
          end
        end
        sorted = []
        root.each do |type|
          sorted.concat(collect_dependency(type, dep))
        end
        sorted.concat(dep.values.flatten)
        sorted
      end

      # removes collected key from dep
      def collect_dependency(type, dep)
        result = [type]
        return result unless dep.key?(type.name)
        dep[type.name].each do |deptype|
          result.concat(collect_dependency(deptype, dep))
        end
        dep.delete(type.name)
        result
      end

      def modulepath_split(modulepath)
        if modulepath.is_a?(::Array)
          modulepath
        else
          modulepath.to_s.split('::')
        end
      end

      def format_skip_element(arr)
        return arr if arr.empty? # Return the array as is if it's empty

        arr[0] = "allowed_nil_attributes = [#{arr[0]}" # Add [ before the first element
        arr[-1] = "#{arr[-1]}]" # Add ] after the last element

        arr # Return the modified array
      end

      def init_line_choice(arr)
        s = arr.map { |elem| "#{"'#{elem[:name]}'"}=>{name:'#{elem[:name]}',class:#{elem[:class]},xsd_path:'#{elem[:xsd_path]}'}" }.join(", ")
        s
      end

      def init_line_sequence(arr)
        s = arr.map { |elem| "{name:'#{elem[:name]}',class:#{elem[:class]},xsd_path:'#{elem[:xsd_path]}'}" }.join(", ")
        return "[#{s}]"
      end

      def init_line_elemC(attrib)
        s = "{name:'#{attrib[:name]}',class:#{attrib[:class]},xsd_path:'#{attrib[:xsd_path]}'}"
        return s
      end
    end
  end
end
