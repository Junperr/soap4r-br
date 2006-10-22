require 'test/unit'
require 'wsdl/parser'
require 'wsdl/soap/wsdl2ruby'
require 'soap/rpc/standaloneServer'
require 'soap/wsdlDriver'


module WSDL; module SimpleContent


class TestSimpleContent < Test::Unit::TestCase
  NS = 'urn:www.example.org:simpleContent'
  class Server < ::SOAP::RPC::StandaloneServer
    def on_init
      add_document_method(self, NS + ':echo', 'echo',
        XSD::QName.new(NS, 'Address'), XSD::QName.new(NS, 'Address'))
      self.mapping_registry = SimpleContentMappingRegistry::LiteralRegistry
    end
  
    def echo(address)
      address
    end
  end

  DIR = File.dirname(File.expand_path(__FILE__))

  Port = 17171

  def setup
    setup_classdef
    setup_server
    @client = nil
  end

  def teardown
    teardown_server
    unless $DEBUG
      File.unlink(pathname('simpleContent.rb'))
      File.unlink(pathname('simpleContentMappingRegistry.rb'))
      File.unlink(pathname('simpleContentDriver.rb'))
    end
    @client.reset_stream if @client
  end

  def setup_server
    @server = Server.new('Test', "urn:www.example.org:simpleContent", '0.0.0.0', Port)
    @server.level = Logger::Severity::ERROR
    @server_thread = start_server_thread(@server)
  end

  def setup_classdef
    gen = WSDL::SOAP::WSDL2Ruby.new
    gen.location = pathname("simplecontent.wsdl")
    gen.basedir = DIR
    gen.logger.level = Logger::FATAL
    gen.opt['classdef'] = nil
    gen.opt['driver'] = nil
    gen.opt['force'] = true
    gen.run
    backupdir = Dir.pwd
    begin
      Dir.chdir(DIR)
      require pathname('simpleContent.rb')
      require pathname('simpleContentMappingRegistry.rb')
      require pathname('simpleContentDriver.rb')
    ensure
      Dir.chdir(backupdir)
    end
  end

  def teardown_server
    @server.shutdown
    @server_thread.kill
    @server_thread.join
  end

  def start_server_thread(server)
    t = Thread.new {
      Thread.current.abort_on_exception = true
      server.start
    }
    t
  end

  def pathname(filename)
    File.join(DIR, filename)
  end

  def test_stub
    @client = SimpleContentService.new("http://localhost:#{Port}/")
    @client.wiredump_dev = STDERR if $DEBUG

    list = PhoneList.new
    list.xmlattr_default = "default"
    phone1 = PhoneNumber.new("12345")
    phone1.xmlattr_type = PhoneNumberType::Fax
    phone2 = PhoneNumber.new("23456")
    phone2.xmlattr_type = PhoneNumberType::Home
    list.phone << phone1 << phone2
    address = Address.new(list, "addr")
    ret = @client.echo(address)

    assert_equal(address.blah, ret.blah)
    assert_equal(2, ret.list.phone.size)
    assert_equal("12345", ret.list.phone[0])
    assert_equal(PhoneNumberType::Fax, ret.list.phone[0].xmlattr_type)
    assert_equal("23456", ret.list.phone[1])
    assert_equal(PhoneNumberType::Home, ret.list.phone[1].xmlattr_type)
  end
end


end; end