require 'net/http/persistent'
require 'rdf' # @see http://rubygems.org/gems/rdf
require 'rdf/ntriples'

module SPARQL
  ##
  # A SPARQL client for RDF.rb.
  #
  # @see http://www.w3.org/TR/rdf-sparql-protocol/
  # @see http://www.w3.org/TR/rdf-sparql-json-res/
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
    # @option options [Hash] :headers
    def initialize(url, options = {}, &block)
      @url, @options = RDF::URI.new(url.to_s), options
      #@headers = {'Accept' => "#{RESULT_JSON}, #{RESULT_XML}, text/plain"}
      @headers = {
        'Accept' => [RESULT_JSON, RESULT_XML, RDF::Format.content_types.keys.map(&:to_s)].join(', ')
      }.merge @options[:headers] || {}
      @http = http_klass(@url.scheme)

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
    # @param  [Array<Symbol>] args
    # @return [Query]
    def select(*args)
      call_query_method(:select, *args)
    end

    ##
    # Executes a `DESCRIBE` query.
    #
    # @param  [Array<Symbol, RDF::URI>] args
    # @return [Query]
    def describe(*args)
      call_query_method(:describe, *args)
    end

    ##
    # Executes a graph `CONSTRUCT` query.
    #
    # @param  [Array<Symbol>] args
    # @return [Query]
    def construct(*args)
      call_query_method(:construct, *args)
    end

    ##
    # Executes a `CLEAR GRAPH` update query.
    #
    # This is a convenience wrapper for the {#clear} method.
    #
    # @example `CLEAR GRAPH`
    #   client.clear_graph("http://example.org/")
    #
    # @param  [RDF::Value, String] graph_uri
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :silent
    # @return [Boolean]
    # @see    http://www.w3.org/TR/sparql11-update/#clear
    def clear_graph(graph_uri, options = {})
      self.clear(:graph, graph_uri, options)
    end

    ##
    # Executes a `CLEAR` update query.
    #
    # @example `CLEAR GRAPH`
    #   client.clear(:graph, RDF::URI("http://example.org/"))
    #
    # @example `CLEAR DEFAULT`
    #   client.clear(:default)
    #
    # @example `CLEAR NAMED`
    #   client.clear(:named)
    #
    # @example `CLEAR ALL`
    #   client.clear(:all)
    #
    # @param  [Symbol, #to_sym] what
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :silent
    # @return [Boolean]
    # @see    http://www.w3.org/TR/sparql11-update/#clear
    def clear(what, *arguments)
      options = arguments.last.is_a?(Hash) ? arguments.pop : {}
      query_text = 'CLEAR '
      query_text += 'SILENT ' if options[:silent]
      case what.to_sym
        when :graph
          case graph_uri = arguments.pop
            when String then graph_uri = RDF::URI(graph_uri)
            when RDF::Value # all good
            else raise ArgumentError, "expected a String or RDF::Value, but got #{graph_uri.inspect}"
          end
          query_text += 'GRAPH ' + RDF::NTriples.serialize(graph_uri)
        when :default then query_text += 'DEFAULT'
        when :named   then query_text += 'NAMED'
        when :all     then query_text += 'ALL'
        else raise ArgumentError, "invalid CLEAR operation: #{what.inspect}"
      end
      query(query_text)
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
    # A mapping of blank node results for this client
    # @private
    def nodes
      @nodes ||= {}
    end

    ##
    # Executes a SPARQL query and returns parsed results.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @option options [Hash] :headers
    # @return [Array<RDF::Query::Solution>]
    def query(query, options = {})
      parse_response(response(query, options), options)
    end

    ##
    # Executes a SPARQL query and returns the Net::HTTP::Response of the result.
    #
    # @param [String, #to_s]   query
    # @param  [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @option options [Hash] :headers
    # @return [String]
    def response(query, options = {})
      @headers['Accept'] = options[:content_type] if options[:content_type]
      get(query, options[:headers] || {}) do |response|
        case response
          when Net::HTTPBadRequest  # 400 Bad Request
            raise MalformedQuery.new(response.body)
          when Net::HTTPClientError # 4xx
            raise ClientError.new(response.body)
          when Net::HTTPServerError # 5xx
            raise ServerError.new(response.body)
          when Net::HTTPSuccess     # 2xx
            response
        end
      end
    end

    ##
    # @param  [Net::HTTPSuccess] response
    # @param  [Hash{Symbol => Object}] options
    # @return [Object]
    def parse_response(response, options = {})
      case content_type = options[:content_type] || response.content_type
        when RESULT_BOOL # Sesame-specific
          response.body == 'true'
        when RESULT_JSON
          self.class.parse_json_bindings(response.body, nodes)
        when RESULT_XML
          self.class.parse_xml_bindings(response.body, nodes)
        else
          parse_rdf_serialization(response, options)
      end
    end

    ##
    # @param  [String, Hash] json
    # @return [<RDF::Query::Solutions>]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_json_bindings(json, nodes = {})
      require 'json' unless defined?(::JSON)
      json = JSON.parse(json.to_s) unless json.is_a?(Hash)

      case
        when json['boolean']
          json['boolean']
        when json['results']
          solutions = json['results']['bindings'].map do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value))
            end
            RDF::Query::Solution.new(row)
          end
          RDF::Query::Solutions.new(solutions)
      end
    end

    ##
    # @param  [Hash{String => String}] value
    # @return [RDF::Value]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_json_value(value, nodes = {})
      case value['type'].to_sym
        when :bnode
          nodes[id = value['value']] ||= RDF::Node.new(id)
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
    # @return [<RDF::Query::Solutions>]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_xml_bindings(xml, nodes = {})
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to?(:force_encoding)
      require 'rexml/document' unless defined?(::REXML::Document)
      xml = REXML::Document.new(xml).root unless xml.is_a?(REXML::Element)

      case
        when boolean = xml.elements['boolean']
          boolean.text == 'true'
        when results = xml.elements['results']
          solutions = results.elements.map do |result|
            row = {}
            result.elements.each do |binding|
              name  = binding.attributes['name'].to_sym
              value = binding.select { |node| node.kind_of?(::REXML::Element) }.first
              row[name] = parse_xml_value(value, nodes)
            end
            RDF::Query::Solution.new(row)
          end
          RDF::Query::Solutions.new(solutions)
      end
    end

    ##
    # @param  [REXML::Element] value
    # @return [RDF::Value]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_xml_value(value, nodes = {})
      case value.name.to_sym
        when :bnode
          nodes[id = value.text] ||= RDF::Node.new(id)
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
    # @param  [Hash{Symbol => Object}] options
    # @return [RDF::Enumerable]
    def parse_rdf_serialization(response, options = {})
      options = {:content_type => response.content_type} if options.empty?
      if reader = RDF::Reader.for(options)
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
    # Returns an HTTP class or HTTP proxy class based on environment http_proxy & https_proxy settings
    # @return [Net::HTTP::Proxy]
    def http_klass(scheme)
      proxy_uri = nil
      case scheme
        when "http"
          proxy_uri = URI.parse(ENV['http_proxy']) unless ENV['http_proxy'].nil?
        when "https"
          proxy_uri = URI.parse(ENV['https_proxy']) unless ENV['https_proxy'].nil?
      end
      klass = Net::HTTP::Persistent.new(self.class.to_s, proxy_uri)
      klass.keep_alive = 120	# increase to 2 minutes
      klass
    end

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
      url.query_values = (url.query_values || {}).merge(:query => query.to_s)

      request = Net::HTTP::Get.new(url.request_uri, @headers.merge(headers))
      request.basic_auth url.user, url.password if url.user && !url.user.empty?
      response = @http.request url, request
      if block_given?
	block.call(response)
      else
	response
      end
    end
  end # Client
end # SPARQL
