# encoding: UTF-8
# WSDL4R - XMLSchema maxInclusive definition for WSDL.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'wsdl/info'


module WSDL
module XMLSchema


class MaxInclusive < Info
  def initialize
    super
  end

  def parse_element(element)
    nil
  end

  def parse_attr(attr, value)
    case attr
    when FixedAttrName
      parent.fixed[:max_inclusive] = to_boolean(value)
    when ValueAttrName
      parent.max_inclusive = value.source
    end
  end
end


end
end
