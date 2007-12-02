module SPARQL

  # <http://www.w3.org/TR/rdf-sparql-query/#QueryForms>
  class Query

    @@prefixes = {}

    def self.prefix(prefix, uri)
      @@prefixes ||= {}
      @@prefixes[prefix.to_sym] = uri
    end

    def self.prefixes
      @@prefixes || {}
    end

    def self.parse(sparql)
      raise NotImplementedError # TODO
      require 'sparql/parser'
    end

    # <http://www.w3.org/TR/rdf-sparql-query/#ask>
    def self.ask(options = {})
      self.new(:ask, options)
    end

    # <http://www.w3.org/TR/rdf-sparql-query/#select>
    def self.select(*variables)
      options = variables.last.respond_to?(:to_hash) ? variables.pop.to_hash : {}
      options[:variables] = variables.empty? ? [:*] : variables
      self.new(:select, options)
    end

    # <http://www.w3.org/TR/rdf-sparql-query/#construct>
    def self.construct(options = {})
      raise NotImplementedError # TODO
      self.new(:construct, options)
    end

    # <http://www.w3.org/TR/rdf-sparql-query/#describe>
    def self.describe(options = {})
      raise NotImplementedError # TODO
      self.new(:describe, options)
    end

    attr_accessor :type
    attr_accessor :options

    def ask?()       options[:type] == :ask end
    def select?()    options[:type] == :select end
    def construct?() options[:type] == :construct end
    def describe?()  options[:type] == :describe end

    def distinct?()  options[:distinct] end
    def reduced?()   options[:reduced] end

    def prefix(prefix, uri)
      options[:prefixes] ||= {}
      options[:prefixes][prefix.to_sym] = uri
      self
    end

    def prefixes
      (@@prefixes || {}).merge(options[:prefixes] || {})
    end

    def from(uri_or_qname)
      options[:from] ||= []
      options[:from] << uri_or_qname
      self
    end

    def where()
      # TODO
      self
    end

    def order_by
      # TODO
      self
    end

    def to_s(with_prefixes = true)
      case type
        when :ask
          query = ['ASK', dataset_clauses, where_clause]
        when :select
          query = ['SELECT']
          query << 'DISTINCT' if distinct?
          query << 'REDUCED' if reduced?
          query += [variables, dataset_clauses, where_clause, solution_modifier]
        when :construct
          query = ['CONSTRUCT', construct_template, dataset_clauses, where_clause, solution_modifier]
        when :describe
          query = ['DESCRIBE', variables_or_uris, dataset_clauses, where_clause, solution_modifier]
        else
          raise NotImplementedError.new("Unknown SPARQL query type: #{type}")
      end
      query = [query.flatten.compact.join(' ')]
      query = prefixes.map { |prefix, uri| "PREFIX #{prefix}: <#{uri}> ." } + query
      query.join("\n")
    end

    protected

      def initialize(type, options = {})
        @type, @options = type, options
      end

      def variables
        options[:variables].map { |var| var == :* ? '*' : "?#{var}" }.join(' ')
      end

      def variables_or_uris
        variables # FIXME
      end

      def construct_template
        # TODO
      end

      def dataset_clauses
        !options[:from] ? nil : options[:from].map { |from| dataset_clause(from) }.join(' ')
      end

      def dataset_clause(uri_or_qname)
        "FROM <#{uri_or_qname.uri}>" # FIXME
      end

      def where_clause
        # TODO
      end

      def solution_modifier
        # TODO
      end

  end
end
