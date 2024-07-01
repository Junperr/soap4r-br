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
        puts "Dumping class definition..."
        puts "group: #{@modelgroups.inspect}"
        puts "simpletype: #{@simpletypes.inspect}"
        puts "complextypes: #{@complextypes.inspect}"
        puts "elements: #{@elements.inspect}"
        puts "attributes: #{@attributes.inspect}"

        result = "require_relative '../SimpleRes'\n" #@todo: changed depending on the structure
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
        puts "Creating element: #{ele.name}"
        qualified = (ele.elementform == 'qualified')
        if ele.local_complextype
          puts "Creating complex type: #{ele.name}"
          create_complextypedef(mpath, ele.name, ele.local_complextype, qualified)
        elsif ele.local_simpletype
          puts "Creating simple type: #{ele.name}"
          create_simpletypedef(mpath, ele.name, ele.local_simpletype, qualified)
        elsif ele.empty?
          puts "Creating simple class: #{ele.name}"
          create_simpleclassdef(mpath, ele.name, nil)
        else
          # ignores type only element
          nil
        end
      end

      def create_simpletypedef(mpath, qname, simpletype, qualified = false)
        if simpletype.restriction
          create_simpletypedef_restriction(mpath, qname, simpletype, qualified)
        elsif simpletype.list
          create_simpletypedef_list(mpath, qname, simpletype, qualified)
        elsif simpletype.union
          create_simpletypedef_union(mpath, qname, simpletype, qualified)
        else
          raise RuntimeError.new("unknown kind of simpletype: #{simpletype}")
        end
      end

      def create_simpletypedef_restriction(mpath, qname, typedef, qualified)
        restriction = typedef.restriction
        puts "restriction: #{typedef.restriction}"
        unless restriction.enumeration? || restriction.min_length? || restriction.max_length? || restriction.pattern? || restriction.length?
          # other restriction are not supported
          return nil
        end
        classname = mapped_class_basename(qname, mpath)
        c = ClassDef.new(classname, 'SimpleRestriction')
        c.comment = "#{qname}"
        define_string_restriction(c, classname, restriction)
        # define_classenum_restriction(c, classname, restriction.enumeration)
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

      def define_string_restriction(c, classname, restriction)
        enum_str = !restriction.enumeration? ? 'nil' : "[#{restriction.enumeration.map { |e| "\"#{e}\"" }.join(', ')}]"
        min_length_str = !restriction.min_length? ? 'nil' : restriction.minlength
        max_length_str = !restriction.max_length? ? 'nil' : restriction.maxlength
        length_str = !restriction.length? ? 'nil' : restriction.length
        pattern_str = !restriction.pattern? ? 'nil' : "/#{restriction.pattern.source}/"
        c.def_code("def initialize(enumeration: #{enum_str}, min_length: #{min_length_str}, max_length: #{max_length_str}, length: #{length_str}, pattern: #{pattern_str})
  super(enumeration: enumeration, min_length: min_length, max_length: max_length, length: length, pattern: pattern)
end")
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

      def create_complextypedef(mpath, qname, type, qualified = false)
        puts "Creating complex type: #{qname} #{type.compoundtype}"
        case type.compoundtype
        when :TYPE_STRUCT, :TYPE_EMPTY
          create_structdef(mpath, qname, type, qualified)

        when :TYPE_ARRAY
          create_arraydef(mpath, qname, type)
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
          if base = typedef.complexcontent.base
            # :TYPE_ARRAY must not be derived (#424)
            basedef = @complextypes[base]
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
        end
        c.comment = "#{qname}"
        c.comment << "\nabstract" if typedef.abstract
        puts "\nc1: #{c.dump}\n"
        parentmodule = mapped_class_name(qname, mpath)
        init_lines, init_params, skip_params =
          parse_elements(c, typedef.elements, qname.namespace, parentmodule)
        puts "init_lines: #{init_lines}"
        puts "init_params: #{init_params}"
        puts "skip_params: #{skip_params}"
        puts "\nc2: #{c.dump}\n"
        unless typedef.attributes.empty?
          define_attribute(c, typedef.attributes)
          init_lines << "@__xmlattr = {}"
        end
        # handle initialize method
        c.def_method('initialize', *init_params) do
          unless skip_params.empty?
            init_lines << "any_nil_or_empty?"
          end
          init_lines.join("\n")

        end
        unless skip_params.empty?
          c.def_method('any_nil_or_empty?', *format_skip_element(skip_params)) do
            "instance_variables.any? do |var|
      # Skip the attribute if it's allowed to be nil or empty
      next if allowed_nil_attributes.include?(var[1..].to_sym)

      value = instance_variable_get(var)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end"
          end
        end
        # puts "\nc3: #{c.dump}\n"
        c
      end

      def parse_elements(c, elements, base_namespace, mpath, as_array = false)
        init_lines = []
        init_params = []
        skip_params = []
        any = false
        elements.each do |element|
          puts "\nelement: #{element} #{element.inspect}"
          puts "element.minoccurs: #{element.minoccurs}"
          puts "element.maxoccurs: #{element.maxoccurs}"
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
            next if element.ref == SchemaName
            name = name_element(element).name
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
              c.innermodule << inner
              typebase = mpath
            end
            unless as_array
              attrname = safemethodname(name)
              varname = safevarname(name)
              c.def_attr(attrname, true, varname)
              if element.minoccurs == 0
                skip_params << ":#{varname}"
              end
              inner2 = check_element(element)
              # classname = mapped_class_basename(qname, mpath)
              if inner2
                init_lines << "@#{varname} = #{mapped_class_basename(element.name, @modulepath)}.new\n@#{varname}.value = #{varname}"
                if element.map_as_array?
                  init_params << "#{varname} = []"
                else
                  init_params << "#{varname} = nil"
                end
                inner2.comment = "inner class for member: #{name}\n" + inner2.comment
                c.innermodule << inner2
                typebase = mpath
              else
                init_lines << "@#{varname} = #{varname}"
                if element.map_as_array?
                  init_params << "#{varname} = []"
                else
                  init_params << "#{varname} = nil"
                end
              end

              c.comment << "\n  #{attrname} - #{create_type_name(typebase, element) || '(any)'}"
              # puts "type name is #{create_type_name(typebase, element)}"
            end
          when WSDL::XMLSchema::Sequence
            child_init_lines, child_init_params =
              parse_elements(c, element.elements, base_namespace, mpath, as_array)
            init_lines.concat(child_init_lines)
            init_params.concat(child_init_params)
          when WSDL::XMLSchema::Choice
            child_init_lines, child_init_params =
              parse_elements(c, element.elements, base_namespace, mpath, as_array)
            init_lines.concat(child_init_lines)
            init_params.concat(child_init_params)
          when WSDL::XMLSchema::Group
            if element.content.nil?
              warn("no group definition found: #{element}")
              next
            end
            child_init_lines, child_init_params =
              parse_elements(c, element.content.elements, base_namespace, mpath, as_array)
            init_lines.concat(child_init_lines)
            init_params.concat(child_init_params)
          else
            raise RuntimeError.new("unknown type: #{element}")
          end
        end
        [init_lines, init_params, skip_params]
      end

      def check_element(element)
        if element.local_simpletype
          c = create_simpletypedef(@modulepath, element.name, element.local_simpletype)
          c
        end
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
    end
  end
end
