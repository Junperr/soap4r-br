# encoding: UTF-8
# WSDL4R - WSDL XML Instance parser library.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'xsd/qname'
require 'xsd/charset'
require 'xsd/datatypes'
require 'xsd/xmlparser'
require 'soap/ns'
require 'wsdl/wsdl'
require 'wsdl/data'
require 'wsdl/xmlSchema/data'
require 'wsdl/soap/data'


module WSDL


class Parser
  include WSDL

  class ParseError < Error; end
  class FormatDecodeError < ParseError; end
  class UnknownElementError < FormatDecodeError; end
  class UnknownAttributeError < FormatDecodeError; end
  class UnexpectedElementError < FormatDecodeError; end
  class ElementConstraintError < FormatDecodeError; end
  class AttributeConstraintError < FormatDecodeError; end

private

  class ParseFrame
    attr_reader :ns
    attr_reader :name
    attr_accessor :node

  private

    def initialize(ns, name, node)
      @ns = ns
      @name = name
      @node = node
    end
  end

public

  def initialize(opt = {})
    @parser = XSD::XMLParser.create_parser(self, opt)
    @parsestack = nil
    @lastnode = nil
    @ignored = {}
    @location = opt[:location]
    @originalroot = opt[:originalroot]
  end

  def parse(string_or_readable)
    @parsestack = []
    @lastnode = nil
    @textbuf = ''
    @parser.do_parse(string_or_readable)
    @lastnode
  end

  def charset
    @parser.charset
  end

  def start_element(name, attrs)
    lastframe = @parsestack.last
    ns = parent = nil
    if lastframe
      ns = lastframe.ns
      parent = lastframe.node
    else
      ns = ::SOAP::NS.new
      parent = nil
    end
    # ns might be the same
    ns, attrs = XSD::XMLParser.filter_ns(ns, attrs)
    node = decode_tag(ns, name, attrs, parent)
    @parsestack << ParseFrame.new(ns, name, node)
  end

  def characters(text)
    lastframe = @parsestack.last
    if lastframe
      # Need not to be cloned because character does not have attr.
      ns = lastframe.ns
      decode_text(ns, text)
    else
      p text if $DEBUG
    end
  end

  def end_element(name)
    lastframe = @parsestack.pop
    unless name == lastframe.name
      raise UnexpectedElementError.new("closing element name '#{name}' does not match with opening element '#{lastframe.name}'")
    end
    decode_tag_end(lastframe.ns, lastframe.node)
    @lastnode = lastframe.node
  end

private

  def decode_tag(ns, name, attrs, parent)
    o = nil
    elename = ns.parse(name)
    if !parent
      if elename == DefinitionsName
	o = Definitions.parse_element(elename)
        o.location = @location
      else
	raise UnknownElementError.new("unknown element: #{elename}")
      end
      o.root = @originalroot if @originalroot   # o.root = o otherwise
    else
      if elename == XMLSchema::AnnotationName
        # only the first annotation element is allowed for each xsd element.
        o = XMLSchema::Annotation.new
      else
        puts "parent=#{parent}"
        o = parent.parse_element(elename)
      end
      if o.nil?
        unless @ignored.key?(elename)
          warn("ignored element: #{elename}")
          @ignored[elename] = elename
        end
	o = Documentation.new	# which accepts any element.
      end
      # node could be a pseudo element.  pseudo element has its own parent.
      o.root = parent.root
      o.parent = parent if o.parent.nil?
    end
    to_array_and_splice_name_to_first(attrs).each do |attr|
      key = attr[:key]
      value = attr[:value]
      attr_ele = ns.parse(key, true)
      value_ele = ns.parse(value, false)
      value_ele.source = value  # for recovery; value may not be a QName
      if o.parse_attr(attr_ele, value_ele).nil?
        unless @ignored.key?(attr_ele)
          warn("ignored attr: #{attr_ele}")
          @ignored[attr_ele] = attr_ele
        end
      end
    end
    o
  end

  def decode_tag_end(ns, node)
    node.parse_epilogue
  end

  def decode_text(ns, text)
    @textbuf << text
  end

  def to_array_and_splice_name_to_first(attrs)
    attrs_name = []
    attrs_other = []
    attrs.each do |key, value|
      if key == "name"
        attrs_name << { :key => key, :value => value }
      elsif
        attrs_other << { :key => key, :value => value }
      end
    end
    attrs_name.concat(attrs_other)
  end
end


end
