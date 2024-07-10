require 'bigdecimal'
require 'date'
require 'time'
require_relative '../../xsd/models/all_class'

SoapToRubyMap = {
  'SOAP::SOAPInteger' => ParsedInteger,
  'SOAP::SOAPNonPositiveInteger' => ParsedInteger,
  'SOAP::SOAPNegativeInteger' => ParsedInteger,
  'SOAP::SOAPLong' => ParsedInteger,
  'SOAP::SOAPInt' => ParsedInteger,
  'SOAP::SOAPShort' => ParsedInteger,
  'SOAP::SOAPByte' => ParsedInteger,
  'SOAP::SOAPNonNegativeInteger' => ParsedInteger,
  'SOAP::SOAPUnsignedLong' => ParsedInteger,
  'SOAP::SOAPUnsignedInt' => ParsedInteger,
  'SOAP::SOAPUnsignedShort' => ParsedInteger,
  'SOAP::SOAPUnsignedByte' => ParsedInteger,
  'SOAP::SOAPPositiveInteger' => ParsedInteger,
  'SOAP::SOAPBoolean' => ParsedBoolean,
  'SOAP::SOAPDecimal' => ParsedBigDecimal,
  'SOAP::SOAPFloat' => ParsedFloat,
  'SOAP::SOAPDouble' => ParsedFloat,
  'SOAP::SOAPDuration' => ParsedString,
  'SOAP::SOAPDateTime' => ParsedDateTime,
  'SOAP::SOAPTime' => ParsedTime,
  'SOAP::SOAPDate' => ParsedDate,
  'SOAP::SOAPBase64' => ParsedBase64Binary
}.freeze
