require 'net/http'
require 'json'
require 'rdf'
require 'sparql/version'

module SPARQL
  ##
  class Client
    ACCEPT_JSON = {'Accept' => 'application/sparql-results+json'}.freeze
    ACCEPT_XML  = {'Accept' => 'application/sparql-results+xml'}.freeze

    attr_reader :url
    attr_reader :options

    ##
    # @param  [String, #to_s]          url
    # @param  [Hash{Symbol => Object}] options
    def initialize(url, options = {}, &block)
      @url, @options = RDF::URI.new(url.to_s), options
      @headers = ACCEPT_JSON

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # @param  [String, #to_s]          url
    # @param  [Hash{Symbol => Object}] options
    def query(query, options = {})
      get(query.to_s) do |response|
        case response
          when Net::HTTPClientError
            # TODO
          when Net::HTTPServerError
            # TODO
          when Net::HTTPSuccess
            parse_response(response)
        end
      end
    end

    ##
    # @param  [Net::HTTPSuccess] response
    # @return [Object]
    def parse_response(response)
      parse_json_bindings(response.body) # FIXME
    end

    ##
    # @param  [Hash, String] json
    # @return [Enumerable<RDF::Query::Solution>]
    def parse_json_bindings(json)
      json = JSON.parse(json.to_s) unless json.is_a?(Hash)
      json['results']['bindings'].map do |row|
        row = row.inject({}) do |cols, (name, value)|
          cols.merge(name => parse_value(value))
        end
        RDF::Query::Solution.new(row)
      end
    end

    ##
    # @param  [Hash] value
    # @return [RDF::Value]
    def parse_value(value)
      case value['type'].to_sym
        when :bnode
          @nodes ||= {}
          @nodes[id = value['value']] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value['value'])
        when :literal
          RDF::Literal.new(value['value']) # TODO
        else nil # FIXME
      end
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
