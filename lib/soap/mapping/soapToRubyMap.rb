require 'bigdecimal'
require 'date'
require 'time'

module SOAP
  SoapToRubyMap = {
    'SOAP::SOAPInteger' => Integer,
    'SOAP::SOAPNonPositiveInteger' => Integer,
    'SOAP::SOAPNegativeInteger' => Integer,
    'SOAP::SOAPLong' => Integer,
    'SOAP::SOAPInt' => Integer,
    'SOAP::SOAPShort' => Integer,
    'SOAP::SOAPByte' => Integer,
    'SOAP::SOAPNonNegativeInteger' => Integer,
    'SOAP::SOAPUnsignedLong' => Integer,
    'SOAP::SOAPUnsignedInt' => Integer,
    'SOAP::SOAPUnsignedShort' => Integer,
    'SOAP::SOAPUnsignedByte' => Integer,
    'SOAP::SOAPPositiveInteger' => Integer,
    'SOAP::SOAPBoolean' => [TrueClass, FalseClass], #peculiar case
    'SOAP::SOAPDecimal' => BigDecimal,
    'SOAP::SOAPFloat' => Float,
    'SOAP::SOAPDouble' => Float,
    'SOAP::SOAPDuration' => String,
    'SOAP::SOAPDateTime' => DateTime,
    'SOAP::SOAPTime' => Time,
    'SOAP::SOAPDate' => Date
  }.freeze
end
