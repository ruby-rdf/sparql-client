require 'net/http'
require 'rexml/document'

module SPARQL

  class Client

    class MalformedQuery < StandardError; end
    class QueryRequestRefused < StandardError; end

    attr_reader :options

    def self.open(*args, &block)
      client = self.new(*args)
      result = block.call(client)
      client.close
      result
    end

    def initialize(endpoint, options = {})
      @url, @options = URI.parse(endpoint), options
    end

    def query(query, options = {})
      request  = compose_request(query, options)
      response = send((options[:method] || :get).to_sym, request)

      case response
        when Net::HTTPClientError
          raise MalformedQuery # FIXME
        when Net::HTTPServerError
          raise QueryRequestRefused # FIXME
        when Net::HTTPSuccess
          content_type = response['content-type'].split(';').first
          parse(response.body, content_type)
      end
    end

    def open?
      @conn && @conn.started?
    end

    def open
      @conn ||= Net::HTTP.new(@url.host, @url.port)
      @conn.read_timeout = options[:timeout] if options[:timeout]
      @conn.start unless @conn.started?
      @conn
    end

    def close
      @conn.finish if @conn && @conn.started?
      @conn = nil
    end

    protected

      def get(request)
        (url = @url.dup).query = request
        open.get(url.request_uri)
      end

      def post(request)
        raise NotImplementedError # TODO
      end

      def compose_request(query, options = {})
        request = ["query=#{URI.escape(query.to_s)}"]

        if uris = options[:default_graphs]
          request += uris.map { |uri| "default-graph-uri=#{URI.escape(uri.to_s)}" }
        end

        if uris = options[:named_graphs]
          request += uris.map { |uri| "named-graph-uri=#{URI.escape(uri.to_s)}" }
        end

        request.join('&')
      end

      def parse(content, content_type)
        case content_type
          when 'application/sparql-results+xml'
            parse_xml(content)
          else
            # TODO: parse RDF graphs returned by DESCRIBE and CONSTRUCT
            raise NotImplementedError, "Unsupported content type #{content_type}"
        end
      end

      # <http://www.w3.org/TR/rdf-sparql-protocol/#query-bindings-http>
      # <http://www.w3.org/TR/rdf-sparql-XMLres/>
      def parse_xml(content)
        xml = REXML::Document.new(content).root

        case
          when boolean = xml.elements['boolean']
            boolean.text == 'true'
          when results = xml.elements['results']
            results.elements.map do |result|
              row = {}
              result.elements.each do |binding|
                name  = binding.attributes['name'].to_sym
                value = parse_xml_value(binding.children.first)
                row[name] = value
              end
              row
            end
          else
            raise NotImplementedError # TODO
        end
      end

      def parse_xml_value(element)
        case element.name.to_sym
          when :uri
            element.text # FIXME
          when :literal
            element.text # FIXME
          when :bnode
            element.text # FIXME
          else
            raise NotImplementedError # TODO
        end
      end

  end
end
