# encoding: UTF-8
# WSDL4R - XMLSchema complexType definition for WSDL.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'wsdl/xmlSchema/content'


module WSDL
module XMLSchema


class Choice < Content
  attr_reader :any

  def initialize
    super()
    @any = nil
  end

  def have_any?
    !!@any
  end

  def choice?
    true
  end

  def parse_element(element)
    puts "Choice#parse_element: element=#{element}"
    case element
    when SequenceName
      o = Sequence.new
      puts "was sequence #{o}"
      @elements << o
      o
    when ChoiceName
      o = Choice.new
      puts "was choice #{o}"
      @elements << o
      o
    when GroupName
      o = Group.new
      puts "was group #{o}"
      @elements << o
      o
    when AnyName
      @any = Any.new
      puts "was any #{@any}"
      @elements << @any
      @any
    else
      super(element)
    end
  end
end


end
end
