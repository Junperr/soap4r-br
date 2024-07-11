# encoding: UTF-8
# WSDL4R - XMLSchema simpleContent restriction definition for WSDL.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'wsdl/info'
require 'xsd/namedelements'


module WSDL
module XMLSchema


class SimpleRestriction < Info
  attr_reader :base
  attr_accessor :length
  attr_accessor :minlength
  attr_accessor :maxlength
  attr_accessor :pattern
  attr_reader :enumeration
  attr_accessor :white_space
  attr_accessor :max_inclusive
  attr_accessor :max_exclusive
  attr_accessor :min_exclusive
  attr_accessor :min_inclusive
  attr_accessor :total_digits
  attr_accessor :fraction_digits
  attr_reader :fixed
  attr_reader :attributes

  def initialize
    super
    @base = nil
    @enumeration = []   # NamedElements?
    @length = nil
    @maxlength = nil
    @minlength = nil
    @pattern = nil
    @white_space = nil
    @max_inclusive = nil
    @max_exclusive = nil
    @min_exclusive = nil
    @min_inclusive = nil
    @total_digits = nil
    @fraction_digits = nil
    @fixed = {}
    @attributes = XSD::NamedElements.new
  end
  
  def valid?(value)
    return false unless check_restriction(value)
    return false unless check_length(value)
    return false unless check_maxlength(value)
    return false unless check_minlength(value)
    return false unless check_pattern(value)
    true
  end

  def enumeration?
    !@enumeration.empty?
  end

  def min_length?
    !@minlength.nil?
  end

  def max_length?
    !@maxlength.nil?
  end

  def pattern?
    !@pattern.nil?
  end

  def length?
    !@length.nil?
  end

  def min_inclusive?
    !@min_inclusive.nil?
  end

  def max_inclusive?
    !@max_inclusive.nil?
  end

  def min_exclusive?
    !@min_exclusive.nil?
  end

  def max_exclusive?
    !@max_exclusive.nil?
  end

  def total_digits?
    !@total_digits.nil?
  end

  def fraction_digits?
    !@fraction_digits.nil?
  end

  def white_space?
    !@white_space.nil?
  end

  def parse_element(element)
    puts "SimpleRestriction#parse_element: element=#{element}"
    case element
    when LengthName
      Length.new
    when MinLengthName
      MinLength.new
    when MaxLengthName
      MaxLength.new
    when PatternName
      Pattern.new
    when EnumerationName
      Enumeration.new
    when WhiteSpaceName
      WhiteSpace.new
    when MaxInclusiveName
      MaxInclusive.new
    when MaxExclusiveName
      MaxExclusive.new
    when MinExclusiveName
      MinExclusive.new
    when MinInclusiveName
      MinInclusive.new
    when TotalDigitsName
      TotalDigits.new
    when FractionDigitsName
      FractionDigits.new
    when AttributeName
      o = Attribute.new
      @attributes << o
      o
    when AttributeGroupName
      o = AttributeGroup.new
      @attributes << o
      o
    when AnyAttributeName
      o = AnyAttribute.new
      @attributes << o
      o
    end
  end

  def parse_attr(attr, value)
    case attr
    when BaseAttrName
      @base = value
    when PatternName
      @pattern_str = value
      @pattern = Regexp.new(@pattern_str)
    end
  end

  def to_s
  <<~OUTPUT
    SimpleRestriction:
      base: #{@base}
      length: #{@length}
      minlength: #{@minlength}
      maxlength: #{@maxlength}
      pattern: #{@pattern}
      enumeration: #{@enumeration.join(', ')}
      whitespace: #{@white_space}
      maxinclusive: #{@max_inclusive}
      maxexclusive: #{@max_exclusive}
      minexclusive: #{@min_exclusive}
      mininclusive: #{@min_inclusive}
      totaldigits: #{@total_digits}
      fractiondigits: #{@fraction_digits}
      fixed: #{@fixed}
      attributes: #{@attributes}
      initialise: enumeration: [\"#{@enumeration.join('", "')}\"], min_length: #{@minlength}, max_length:  #{@maxlength}, pattern: #{@pattern}
  OUTPUT
end

private

  def check_restriction(value)
    @enumeration.empty? or @enumeration.include?(value)
  end

  def check_length(value)
    @length.nil? or value.size == @length
  end

  def check_maxlength(value)
    @maxlength.nil? or value.size <= @maxlength
  end

  def check_minlength(value)
    @minlength.nil? or value.size >= @minlength
  end

  def check_pattern(value)
    @pattern.nil? or @pattern =~ value
  end
end


end
end
