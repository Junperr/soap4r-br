# encoding: UTF-8
# XSD4R - Generating method definition code
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'xsd/codegen/gensupport'
require 'xsd/codegen/commentdef'


module XSD
module CodeGen


class MethodDef
  include GenSupport
  include CommentDef

  attr_accessor :definition

  def initialize(name, *params)
    klass, mname = name.split('.', 2)
    if mname.nil?
      mname, klass = klass, mname
    end
    unless safemethodname?(mname)
      raise ArgumentError.new("name '#{name}' seems to be unsafe")
    end
    if klass and klass != 'self' and !safeconstname(klass)
      raise ArgumentError.new("name '#{name}' seems to be unsafe")
    end
    @name = name
    @params = params
    @comment = nil
    @definition = yield if block_given?
    puts "MethodDef#initialize: @name=#{@name}, @params=#{@params}, @comment=#{@comment}, @definition=#{@definition}"
  end

  def dump
    puts "\nMethodDef#dump: @name=#{@name}, @params=#{@params}, @comment=#{@comment}, @definition=#{@definition}"
    buf = ""
    buf << dump_comment if @comment
    buf << dump_method_def
    buf << dump_definition if @definition and !@definition.empty?
    buf << dump_method_def_end
    buf
  end

private

  def dump_method_def
    if @params.empty?
      format("def #{@name}")
    else
      format("def #{@name}(#{@params.join(", ")})")
    end
  end

  def dump_method_def_end
    format("end")
  end

  def dump_definition
    format(@definition, 2)
  end
end


end
end
