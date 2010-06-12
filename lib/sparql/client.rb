require 'net/http'
require 'rdf'
require 'rdf/ntriples'

module SPARQL
  ##
  # A SPARQL client for RDF.rb.
  class Client
    autoload :Query,      'sparql/client/query'
    autoload :Repository, 'sparql/client/repository'
    autoload :VERSION,    'sparql/client/version'

    class ClientError < StandardError; end
    class MalformedQuery < ClientError; end
    class ServerError < StandardError; end

    RESULT_BOOL = 'text/boolean'.freeze # Sesame-specific
    RESULT_JSON = 'application/sparql-results+json'.freeze
    RESULT_XML  = 'application/sparql-results+xml'.freeze
    ACCEPT_JSON = {'Accept' => RESULT_JSON}.freeze
    ACCEPT_XML  = {'Accept' => RESULT_XML}.freeze

    attr_reader :url
    attr_reader :options

    ##
    # @param  [String, #to_s]          url
    # @param  [Hash{Symbol => Object}] options
    def initialize(url, options = {}, &block)
      @url, @options = RDF::URI.new(url.to_s), options
      @headers = {'Accept' => "#{RESULT_JSON}, #{RESULT_XML}, text/plain"}

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # Executes a boolean `ASK` query.
    #
    # @return [Query]
    def ask(*args)
      call_query_method(:ask, *args)
    end

    ##
    # Executes a tuple `SELECT` query.
    #
    # @param  [Array<Symbol>] variables
    # @return [Query]
    def select(*args)
      call_query_method(:select, *args)
    end

    ##
    # Executes a `DESCRIBE` query.
    #
    # @param  [Array<Symbol, RDF::URI>] variables
    # @return [Query]
    def describe(*args)
      call_query_method(:describe, *args)
    end

    ##
    # Executes a graph `CONSTRUCT` query.
    #
    # @param  [Array<Symbol>] pattern
    # @return [Query]
    def construct(*args)
      call_query_method(:construct, *args)
    end

    ##
    # @private
    def call_query_method(meth, *args)
      client = self
      result = Query.send(meth, *args)
      (class << result; self; end).send(:define_method, :execute) do
        client.query(self)
      end
      result
    end

    ##
    # Executes a SPARQL query.
    #
    # @param  [String, #to_s]          url
    # @param  [Hash{Symbol => Object}] options
    # @return [Array<RDF::Query::Solution>]
    def query(query, options = {})
      get(query) do |response|
        case response
          when Net::HTTPBadRequest  # 400 Bad Request
            raise MalformedQuery.new(response.body)
          when Net::HTTPClientError # 4xx
            raise ClientError.new(response.body)
          when Net::HTTPServerError # 5xx
            raise ServerError.new(response.body)
          when Net::HTTPSuccess     # 2xx
            parse_response(response)
        end
      end
    end

    ##
    # @param  [Net::HTTPSuccess] response
    # @return [Object]
    def parse_response(response)
      case content_type = response.content_type
        when RESULT_BOOL # Sesame-specific
          response.body == 'true'
        when RESULT_JSON
          parse_json_bindings(response.body)
        when RESULT_XML
          parse_xml_bindings(response.body)
        else
          parse_rdf_serialization(response)
      end
    end

    ##
    # @param  [String, Hash] json
    # @return [Enumerable<RDF::Query::Solution>]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#results
    def parse_json_bindings(json)
      require 'json' unless defined?(::JSON)
      json = JSON.parse(json.to_s) unless json.is_a?(Hash)

      case
        when json['boolean']
          json['boolean']
        when json['results']
          json['results']['bindings'].map do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value))
            end
            RDF::Query::Solution.new(row)
          end
      end
    end

    ##
    # @param  [Hash{String => String}] value
    # @return [RDF::Value]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def parse_json_value(value)
      case value['type'].to_sym
        when :bnode
          @nodes ||= {}
          @nodes[id = value['value']] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value['value'])
        when :literal
          RDF::Literal.new(value['value'], :language => value['xml:lang'])
        when :'typed-literal'
          RDF::Literal.new(value['value'], :datatype => value['datatype'])
        else nil
      end
    end

    ##
    # @param  [String, REXML::Element] xml
    # @return [Enumerable<RDF::Query::Solution>]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#results
    def parse_xml_bindings(xml)
      require 'rexml/document' unless defined?(::REXML::Document)
      xml = REXML::Document.new(xml).root unless xml.is_a?(REXML::Element)

      case
        when boolean = xml.elements['boolean']
          boolean.text == 'true'
        when results = xml.elements['results']
          results.elements.map do |result|
            row = {}
            result.elements.each do |binding|
              name  = binding.attributes['name'].to_sym
              value = binding.select { |node| node.kind_of?(::REXML::Element) }.first
              row[name] = parse_xml_value(value)
            end
            RDF::Query::Solution.new(row)
          end
      end
    end

    ##
    # @param  [REXML::Element] value
    # @return [RDF::Value]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def parse_xml_value(value)
      case value.name.to_sym
        when :bnode
          @nodes ||= {}
          @nodes[id = value.text] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value.text)
        when :literal
          RDF::Literal.new(value.text, {
            :language => value.attributes['xml:lang'],
            :datatype => value.attributes['datatype'],
          })
        else nil
      end
    end

    ##
    # @param  [Net::HTTPSuccess] response
    # @return [RDF::Enumerable]
    def parse_rdf_serialization(response)
      if reader = RDF::Reader.for(:content_type => response.content_type)
        reader.new(response.body)
      end
    end

    ##
    # Outputs a developer-friendly representation of this object to `stderr`.
    #
    # @return [void]
    def inspect!
      warn(inspect)
    end

    ##
    # Returns a developer-friendly representation of this object.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, url.to_s)
    end

    protected

    ##
    # Performs an HTTP GET request against the SPARQL endpoint.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def get(query, headers = {}, &block)
      url = self.url.dup
      url.query_values = {:query => query.to_s}

      Net::HTTP.start(url.host, url.port) do |http|
        response = http.get(url.path + "?#{url.query}", @headers.merge(headers))
        if block_given?
          block.call(response)
        else
          response
        end
      end
    end
  end
end
