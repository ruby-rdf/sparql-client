require 'net/http/persistent' # @see http://rubygems.org/gems/net-http-persistent
require 'rdf'                 # @see http://rubygems.org/gems/rdf
require 'rdf/ntriples'        # @see http://rubygems.org/gems/rdf
begin
  require 'nokogiri'
rescue LoadError
  require 'rexml/document'
end

module SPARQL
  ##
  # A SPARQL 1.0/1.1 client for RDF.rb.
  #
  # @see http://www.w3.org/TR/sparql11-query/
  # @see http://www.w3.org/TR/sparql11-protocol/
  # @see http://www.w3.org/TR/sparql11-results-json/
  # @see http://www.w3.org/TR/sparql11-results-csv-tsv/
  class Client
    autoload :Query,      'sparql/client/query'
    autoload :Repository, 'sparql/client/repository'
    autoload :Update,     'sparql/client/update'
    autoload :VERSION,    'sparql/client/version'

    class ClientError < StandardError; end
    class MalformedQuery < ClientError; end
    class ServerError < StandardError; end

    RESULT_JSON = 'application/sparql-results+json'.freeze
    RESULT_XML  = 'application/sparql-results+xml'.freeze
    RESULT_CSV  = 'text/csv'.freeze
    RESULT_TSV  = 'text/tab-separated-values'.freeze
    RESULT_BOOL = 'text/boolean'.freeze                           # Sesame-specific
    RESULT_BRTR = 'application/x-binary-rdf-results-table'.freeze # Sesame-specific
    ACCEPT_JSON = {'Accept' => RESULT_JSON}.freeze
    ACCEPT_XML  = {'Accept' => RESULT_XML}.freeze
    ACCEPT_CSV  = {'Accept' => RESULT_CSV}.freeze
    ACCEPT_TSV  = {'Accept' => RESULT_TSV}.freeze
    ACCEPT_BRTR = {'Accept' => RESULT_BRTR}.freeze

    DEFAULT_PROTOCOL = 1.0
    DEFAULT_METHOD   = :post

    XMLNS = {'sparql' => 'http://www.w3.org/2005/sparql-results#'}.freeze

    ##
    # The SPARQL endpoint URL, or an RDF::Queryable instance, to use the native SPARQL engine.
    #
    # @return [RDF::URI, RDF::Queryable]
    attr_reader :url

    ##
    # The HTTP headers that will be sent in requests to the endpoint.
    #
    # @return [Hash{String => String}]
    attr_reader :headers

    ##
    # Any miscellaneous configuration.
    #
    # @return [Hash{Symbol => Object}]
    attr_reader :options

    ##
    # Initialize a new sparql client, either using the URL of
    # a SPARQL endpoint or an `RDF::Queryable` instance to use
    # the native SPARQL gem.
    #
    # @param  [String, RDF::Queryable, #to_s]          url
    #   URL of endpoint, or queryable object.
    # @param  [Hash{Symbol => Object}] options
    # @option options [Symbol] :method (DEFAULT_METHOD)
    # @option options [Number] :protocol (DEFAULT_PROTOCOL)
    # @option options [Hash] :headers
    # @option options [Hash] :read_timeout
    def initialize(url, options = {}, &block)
      case url
      when RDF::Queryable
        @url, @options = url, options.dup
      else
        @url, @options = RDF::URI.new(url.to_s), options.dup
        @headers = {
          'Accept' => [RESULT_JSON, RESULT_XML, "#{RESULT_TSV};p=0.8", "#{RESULT_CSV};p=0.2", RDF::Format.content_types.keys.map(&:to_s)].join(', ')
        }.merge(@options.delete(:headers) || {})
        @http = http_klass(@url.scheme)
      end

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
    # Executes an `INSERT DATA` operation.
    #
    # This requires that the endpoint support SPARQL 1.1 Update.
    #
    # Note that for inserting non-trivial amounts of data, you probably
    # ought to consider using the RDF store's native bulk-loading facilities
    # or APIs, as `INSERT DATA` operations entail comparably higher
    # parsing overhead.
    #
    # @example Inserting data constructed ad-hoc
    #   client.insert_data(RDF::Graph.new { |graph|
    #     graph << [:jhacker, RDF::FOAF.name, "J. Random Hacker"]
    #   })
    #
    # @example Inserting data sourced from a file or URL
    #   data = RDF::Graph.load("http://rdf.rubyforge.org/doap.nt")
    #   client.insert_data(data)
    #
    # @example Inserting data into a named graph
    #   client.insert_data(data, :graph => "http://example.org/")
    #
    # @param  [RDF::Graph] data
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI, String] :graph
    # @return [void] `self`
    # @see    http://www.w3.org/TR/sparql11-update/#insertData
    def insert_data(data, options = {})
      self.update(Update::InsertData.new(data, options))
    end

    ##
    # Executes a `DELETE DATA` operation.
    #
    # This requires that the endpoint support SPARQL 1.1 Update.
    #
    # @example Deleting data sourced from a file or URL
    #   data = RDF::Graph.load("http://rdf.rubyforge.org/doap.nt")
    #   client.delete_data(data)
    #
    # @example Deleting data from a named graph
    #   client.delete_data(data, :graph => "http://example.org/")
    #
    # @param  [RDF::Graph] data
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI, String] :graph
    # @return [void] `self`
    # @see    http://www.w3.org/TR/sparql11-update/#deleteData
    def delete_data(data, options = {})
      self.update(Update::DeleteData.new(data, options))
    end

    ##
    # Executes a `DELETE/INSERT` operation.
    #
    # This requires that the endpoint support SPARQL 1.1 Update.
    #
    # @param  [RDF::Enumerable] delete_graph
    # @param  [RDF::Enumerable] insert_graph
    # @param  [RDF::Enumerable] where_graph
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI, String] :graph
    # @return [void] `self`
    # @see    http://www.w3.org/TR/sparql11-update/#deleteInsert
    def delete_insert(delete_graph, insert_graph = nil, where_graph = nil, options = {})
      puts "'#{insert_graph}' '#{delete_graph}' '#{where_graph}'"
      self.update(Update::DeleteInsert.new(delete_graph, insert_graph, where_graph, options))
    end

    ##
    # Executes a `CLEAR GRAPH` operation.
    #
    # This is a convenience wrapper for the {#clear} method.
    #
    # @example `CLEAR GRAPH <http://example.org/>`
    #   client.clear_graph("http://example.org/")
    #
    # @param  [RDF::URI, String] graph_uri
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :silent
    # @return [void] `self`
    # @see    http://www.w3.org/TR/sparql11-update/#clear
    def clear_graph(graph_uri, options = {})
      self.clear(:graph, graph_uri, options)
    end

    ##
    # Executes a `CLEAR` operation.
    #
    # This requires that the endpoint support SPARQL 1.1 Update.
    #
    # @example `CLEAR GRAPH <http://example.org/>`
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
    # @overload clear(what, *arguments)
    #   @param  [Symbol, #to_sym] what
    #   @param  [Array] arguments splat of other arguments to {Update::Clear}.
    #   @option options [Boolean] :silent
    #   @return [void] `self`
    #
    # @overload clear(what, *arguments, options = {})
    #   @param  [Symbol, #to_sym] what
    #   @param  [Array] arguments splat of other arguments to {Update::Clear}.
    #   @param  [Hash{Symbol => Object}] options
    #   @option options [Boolean] :silent
    #   @return [void] `self`
    #
    # @see    http://www.w3.org/TR/sparql11-update/#clear
    def clear(what, *arguments)
      self.update(Update::Clear.new(what, *arguments))
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
    # Returns a mapping of blank node results for this client.
    #
    # @private
    def nodes
      @nodes ||= {}
    end

    ##
    # Executes a SPARQL query and returns the parsed results.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @option options [Hash] :headers
    # @return [Array<RDF::Query::Solution>]
    # @see    http://www.w3.org/TR/sparql11-protocol/#query-operation
    def query(query, options = {})
      @op = :query
      case @url
      when RDF::Queryable
        require 'sparql' unless defined?(::SPARQL::Grammar)
        SPARQL.execute(query, @url, options)
      else
        parse_response(response(query, options), options)
      end
    end

    ##
    # Executes a SPARQL update operation.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @option options [Hash] :headers
    # @return [void] `self`
    # @see    http://www.w3.org/TR/sparql11-protocol/#update-operation
    def update(query, options = {})
      @op = :update
      case @url
      when RDF::Queryable
        require 'sparql' unless defined?(::SPARQL::Grammar)
        SPARQL.execute(query, @url, options)
      else
        parse_response(response(query, options), options)
      end
      self
    end

    ##
    # Executes a SPARQL query and returns the Net::HTTP::Response of the
    # result.
    #
    # @param [String, #to_s]   query
    # @param  [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @option options [Hash] :headers
    # @return [String]
    def response(query, options = {})
      headers = options[:headers] || {}
      headers['Accept'] = options[:content_type] if options[:content_type]
      request(query, headers) do |response|
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
      case options[:content_type] || response.content_type
        when RESULT_BOOL # Sesame-specific
          response.body == 'true'
        when RESULT_JSON
          self.class.parse_json_bindings(response.body, nodes)
        when RESULT_XML
          self.class.parse_xml_bindings(response.body, nodes)
        when RESULT_CSV
          self.class.parse_csv_bindings(response.body, nodes)
        when RESULT_TSV
          self.class.parse_tsv_bindings(response.body, nodes)
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
        when json.has_key?('boolean')
          json['boolean']
        when json.has_key?('results')
          solutions = json['results']['bindings'].map do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value, nodes))
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
    # @param  [String, Array<Array<String>>] csv
    # @return [<RDF::Query::Solutions>]
    # @see    http://www.w3.org/TR/sparql11-results-csv-tsv/
    def self.parse_csv_bindings(csv, nodes = {})
      require 'csv' unless defined?(::CSV)
      csv = CSV.parse(csv.to_s) unless csv.is_a?(Array)
      vars = csv.shift
      solutions = RDF::Query::Solutions.new
      csv.each do |row|
        solution = RDF::Query::Solution.new
        row.each_with_index do |v, i|
          term = case v
          when /^_:(.*)$/ then nodes[$1] ||= RDF::Node($1)
          when /^\w+:.*$/ then RDF::URI(v)
          else RDF::Literal(v)
          end
          solution[vars[i].to_sym] = term
        end
        solutions << solution
      end
      solutions
    end

    ##
    # @param  [String, Array<Array<String>>] tsv
    # @return [<RDF::Query::Solutions>]
    # @see    http://www.w3.org/TR/sparql11-results-csv-tsv/
    def self.parse_tsv_bindings(tsv, nodes = {})
      tsv = tsv.lines.map {|l| l.chomp.split("\t")} unless tsv.is_a?(Array)
      vars = tsv.shift.map {|h| h.sub(/^\?/, '')}
      solutions = RDF::Query::Solutions.new
      tsv.each do |row|
        solution = RDF::Query::Solution.new
        row.each_with_index do |v, i|
          if !v.empty?
            term = RDF::NTriples.unserialize(v) || case v
            when /^\d+\.\d*[eE][+-]?[0-9]+$/  then RDF::Literal::Double.new(v)
            when /^\d*\.\d+[eE][+-]?[0-9]+$/  then RDF::Literal::Double.new(v)
            when /^\d*\.\d+$/                 then RDF::Literal::Decimal.new(v)
            when /^\d+$/                      then RDF::Literal::Integer.new(v)
            else
              RDF::Literal(v)
            end
            nodes[term.id] = term if term.is_a? RDF::Node
            solution[vars[i].to_sym] = term
          end
        end
        solutions << solution
      end
      solutions
    end

    ##
    # @param  [String, IO, Nokogiri::XML::Node, REXML::Element] xml
    # @return [<RDF::Query::Solutions>]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_xml_bindings(xml, nodes = {})
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to?(:force_encoding)

      if defined?(::Nokogiri)
        xml = Nokogiri::XML(xml).root unless xml.is_a?(Nokogiri::XML::Document)
        case
          when boolean = xml.xpath("//sparql:boolean", XMLNS)[0]
            boolean.text == 'true'
          when results = xml.xpath("//sparql:results", XMLNS)[0]
            solutions = results.elements.map do |result|
              row = {}
              result.elements.each do |binding|
                name  = binding.attr('name').to_sym
                value = binding.elements.first
                row[name] = parse_xml_value(value, nodes)
              end
              RDF::Query::Solution.new(row)
            end
            RDF::Query::Solutions.new(solutions)
        end
      else
        # REXML
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
    end

    ##
    # @param  [Nokogiri::XML::Element, REXML::Element] value
    # @return [RDF::Value]
    # @see    http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_xml_value(value, nodes = {})
      case value.name.to_sym
        when :bnode
          nodes[id = value.text] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value.text)
        when :literal
          lang     = value.respond_to?(:attr) ? value.attr('xml:lang') : value.attributes['xml:lang']
          datatype = value.respond_to?(:attr) ? value.attr('datatype') : value.attributes['datatype']
          RDF::Literal.new(value.text, :language => lang, :datatype => datatype)
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
    # Serializes a URI or URI string into SPARQL syntax.
    #
    # @param  [RDF::URI, String] uri
    # @return [String]
    # @private
    def self.serialize_uri(uri)
      case uri
        when String then RDF::NTriples.serialize(RDF::URI(uri))
        when RDF::URI then RDF::NTriples.serialize(uri)
        else raise ArgumentError, "expected the graph URI to be a String or RDF::URI, but got #{uri.inspect}"
      end
    end

    ##
    # Serializes an `RDF::Value` into SPARQL syntax.
    #
    # @param  [RDF::Value] value
    # @return [String]
    # @private
    def self.serialize_value(value)
      # SPARQL queries are UTF-8, but support ASCII-style Unicode escapes, so
      # the N-Triples serializer is fine unless it's a variable:
      case
        when value.nil? then RDF::Query::Variable.new.to_s
        when value.variable? then value.to_s
        else RDF::NTriples.serialize(value)
      end
    end

    ##
    # Serializes a SPARQL predicate
    #
    # @param [RDF::Value, Array, String] value
    # @param [Fixnum] rdepth
    # @return [String]
    # @private
    def self.serialize_predicate(value,rdepth=0)
      case value
        when String then value
        when Array
          s = value.map{|v|serialize_predicate(v,rdepth+1)}.join
          rdepth > 0 ? "(#{s})" : s
        when RDF::Value
          # abbreviate RDF.type in the predicate position per SPARQL grammar
          value.equal?(RDF.type) ? 'a' : serialize_value(value)
      end
    end

    ##
    # Serializes a SPARQL graph
    #
    # @param [RDF::Enumerable] patterns
    # @return [String]
    # @private
    def self.serialize_patterns(patterns)
      patterns.map do |pattern|
        serialized_pattern = RDF::Statement.from(pattern).to_triple.each_with_index.map do |v, i|
          if i == 1
            SPARQL::Client.serialize_predicate(v)
         else
            SPARQL::Client.serialize_value(v)
          end
        end
        serialized_pattern.join(' ') + ' .'
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
    # Returns an HTTP class or HTTP proxy class based on the `http_proxy`
    # and `https_proxy` environment variables.
    #
    # @param  [String] scheme
    # @return [Net::HTTP::Proxy]
    def http_klass(scheme)
      proxy_url = nil
      case scheme
        when 'http'
          value = ENV['http_proxy']
          proxy_url = URI.parse(value) unless value.nil? || value.empty?
        when 'https'
          value = ENV['https_proxy']
          proxy_url = URI.parse(value) unless value.nil? || value.empty?
      end
      klass = Net::HTTP::Persistent.new(self.class.to_s, proxy_url)
      klass.keep_alive = 120 # increase to 2 minutes
      klass.read_timeout = @options[:read_timeout] || 60
      klass
    end

    ##
    # Performs an HTTP request against the SPARQL endpoint.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    # @see    http://www.w3.org/TR/sparql11-protocol/#query-operation
    def request(query, headers = {}, &block)
      method = (self.options[:method] || DEFAULT_METHOD).to_sym
      request = send("make_#{method}_request", query, headers)

      request.basic_auth(url.user, url.password) if url.user && !url.user.empty?

      response = @http.request(url, request)
      if block_given?
        block.call(response)
      else
        response
      end
    end

    ##
    # Constructs an HTTP GET request according to the SPARQL Protocol.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{String => String}] headers
    # @return [Net::HTTPRequest]
    # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-get
    def make_get_request(query, headers = {})
      url = self.url.dup
      url.query_values = (url.query_values || {}).merge(:query => query.to_s)
      request = Net::HTTP::Get.new(url.request_uri, self.headers.merge(headers))
      request
    end

    ##
    # Constructs an HTTP POST request according to the SPARQL Protocol.
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{String => String}] headers
    # @return [Net::HTTPRequest]
    # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-post-direct
    # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-post-urlencoded
    def make_post_request(query, headers = {})
      request = Net::HTTP::Post.new(self.url.request_uri, self.headers.merge(headers))
      case (self.options[:protocol] || DEFAULT_PROTOCOL).to_s
        when '1.1'
          request['Content-Type'] = 'application/sparql-' + (@op || :query).to_s
          request.body = query.to_s
        when '1.0'
          request.set_form_data((@op || :query) => query.to_s)
        else
          raise ArgumentError, "unknown SPARQL protocol version: #{self.options[:protocol].inspect}"
      end
      request
    end
  end # Client
end # SPARQL
