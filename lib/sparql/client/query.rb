class SPARQL::Client
  ##
  # A SPARQL query builder.
  #
  # @example Iterating over all found solutions
  #   query.each_solution { |solution| puts solution.inspect }
  #
  class Query < RDF::Query
    ##
    # The form of the query.
    #
    # @return [:select, :ask, :construct, :describe]
    # @see    http://www.w3.org/TR/sparql11-query/#QueryForms
    attr_reader :form

    ##
    # @return [Hash{Symbol => Object}]
    attr_reader :options

    ##
    # Creates a boolean `ASK` query.
    #
    # @example ASK WHERE { ?s ?p ?o . }
    #   Query.ask.where([:s, :p, :o])
    #
    # @param  [Hash{Symbol => Object}] options (see {#initialize})
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#ask
    def self.ask(options = {})
      self.new(:ask, options)
    end

    ##
    # Creates a tuple `SELECT` query.
    #
    # @example SELECT * WHERE { ?s ?p ?o . }
    #   Query.select.where([:s, :p, :o])
    #
    # @example SELECT ?s WHERE {?s ?p ?o .}
    #   Query.select(:s).where([:s, :p, :o])
    #
    # @example SELECT COUNT(?uri as ?c) WHERE {?uri a owl:Class}
    #   Query.select(count: {uri: :c}).where([:uri, RDF.type, RDF::OWL.Class])
    #
    # @param  [Array<Symbol>]          variables
    # @return [Query]
    #
    # @overload self.select(*variables, options)
    #   @param  [Array<Symbol>]          variables
    #   @param  [Hash{Symbol => Object}] options (see {#initialize})
    #   @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#select
    def self.select(*variables)
      options = variables.last.is_a?(Hash) ? variables.pop : {}
      self.new(:select, options).select(*variables)
    end

    ##
    # Creates a `DESCRIBE` query.
    #
    # @example DESCRIBE * WHERE { ?s ?p ?o . }
    #   Query.describe.where([:s, :p, :o])
    #
    # @param  [Array<Symbol, RDF::URI>] variables
    # @return [Query]
    #
    # @overload self.describe(*variables, options)
    #   @param  [Array<Symbol, RDF::URI>] variables
    #   @param  [Hash{Symbol => Object}] options (see {#initialize})
    #   @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#describe
    def self.describe(*variables)
      options = variables.last.is_a?(Hash) ? variables.pop : {}
      self.new(:describe, options).describe(*variables)
    end

    ##
    # Creates a graph `CONSTRUCT` query.
    #
    # @example CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }
    #   Query.construct([:s, :p, :o]).where([:s, :p, :o])
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns
    # @return [Query]
    #
    # @overload self.construct(*variables, options)
    #   @param  [Array<RDF::Query::Pattern, Array>] patterns
    #   @param  [Hash{Symbol => Object}] options (see {#initialize})
    #   @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#construct
    def self.construct(*patterns)
      options = patterns.last.is_a?(Hash) ? patterns.pop : {}
      self.new(:construct, options).construct(*patterns) # FIXME
    end

    ##
    # @param  [Symbol, #to_s]          form
    # @overload self.construct(*variables, options)
    #   @param  [Symbol, #to_s]          form
    #   @param  [Hash{Symbol => Object}] options (see {Client#initialize})
    #   @option options [Hash{Symbol => Symbol}] :count
    #     Contents are symbols relating a variable described within the query,
    #     to the projected variable.
    #     
    # @yield  [query]
    # @yieldparam [Query]
    def initialize(form = :ask, options = {}, &block)
      @subqueries = []
      @form = form.respond_to?(:to_sym) ? form.to_sym : form.to_s.to_sym
      super([], options, &block)
    end

    ##
    # @example ASK WHERE { ?s ?p ?o . }
    #   query.ask.where([:s, :p, :o])
    #
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#ask
    def ask
      @form = :ask
      self
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . }
    #   query.select.where([:s, :p, :o])
    #
    # @example SELECT ?s WHERE {?s ?p ?o .}
    #   query.select(:s).where([:s, :p, :o])
    #
    # @example SELECT COUNT(?uri as ?c) WHERE {?uri a owl:Class}
    #   query.select(count: {uri: :c}).where([:uri, RDF.type, RDF::OWL.Class])
    #
    # @param  [Array<Symbol>] variables
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#select
    def select(*variables)
      @values = variables.map { |var| [var, RDF::Query::Variable.new(var)] }
      self
    end

    ##
    # @example DESCRIBE * WHERE { ?s ?p ?o . }
    #   query.describe.where([:s, :p, :o])
    #
    # @param  [Array<Symbol>] variables
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#describe
    def describe(*variables)
      @values = variables.map { |var|
        [var, var.is_a?(RDF::URI) ? var : RDF::Query::Variable.new(var)]
      }
      self
    end

    ##
    # @example CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }
    #   query.construct([:s, :p, :o]).where([:s, :p, :o])
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#construct
    def construct(*patterns)
      options[:template] = build_patterns(patterns)
      self
    end

    ##
    # @example SELECT * FROM <a> WHERE \{ ?s ?p ?o . \}
    #   query.select.from(RDF::URI.new(a)).where([:s, :p, :o])
    #
    # @param [RDF::URI] uri
    # @return [Query]
    # @see http://www.w3.org/TR/sparql11-query/#specifyingDataset
    def from(uri)
      options[:from] = uri
      self
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . }
    #   query.select.where([:s, :p, :o])
    #   query.select.whether([:s, :p, :o])
    #
    # @example SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }
    #   subquery = query.select.where([:s, :p, :o])
    #   query.select.where([:s, :p, :o], subquery)
    #
    # @example SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }
    #   query.select.where([:s, :p, :o]) do |q|
    #     q.select.where([:s, :p, :o])
    #   end
    #
    # Block form can be used for chaining calls in addition to creating sub-select queries.
    #
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o
    #   query.select.where([:s, :p, :o]) do
    #     order(:o)
    #   end
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns_queries
    #   splat of zero or more patterns followed by zero or more queries.
    # @yield [query]
    #   Yield form with or without argument; without an argument, evaluates within the query.
    # @yieldparam [SPARQL::Client::Query] query Actually a delegator to query. Methods other than `#select` are evaluated against `self`. For `#select`, a new Query is created, and the result added as a subquery.
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#GraphPattern
    def where(*patterns_queries, &block)
      subqueries, patterns = patterns_queries.partition {|pq| pq.is_a? SPARQL::Client::Query}
      @patterns += build_patterns(patterns)
      @subqueries += subqueries

      if block_given?
        decorated_query = WhereDecorator.new(self)
        case block.arity
          when 1 then block.call(decorated_query)
          else decorated_query.instance_eval(&block)
        end
      end
      self
    end

    alias_method :whether, :where

    # @private
    class WhereDecorator < SimpleDelegator
      def select(*variables)
        query = SPARQL::Client::Query.select(*variables)
        __getobj__.instance_variable_get(:@subqueries) << query
        query
      end
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o
    #   query.select.where([:s, :p, :o]).order(:o)
    #   query.select.where([:s, :p, :o]).order_by(:o)
    #
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ?p
    #   query.select.where([:s, :p, :o]).order_by(:o, :p)
    #
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o) DESC(?p)
    #   query.select.where([:s, :p, :o]).order_by(:o => :asc, :p => :desc)
    #
    # @param  [Array<Symbol, String>] variables
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modOrderBy
    def order(*variables)
      options[:order_by] = variables
      self
    end

    alias_method :order_by, :order

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)
    #   query.select.where([:s, :p, :o]).order.asc(:o)
    #   query.select.where([:s, :p, :o]).asc(:o)
    #
    # @param  [Array<Symbol, String>] var
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modOrderBy
    def asc(var)
      (options[:order_by] ||= []) << {var => :asc}
      self
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)
    #   query.select.where([:s, :p, :o]).order.desc(:o)
    #   query.select.where([:s, :p, :o]).desc(:o)
    #
    # @param  [Array<Symbol, String>] var
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modOrderBy
    def desc(var)
      (options[:order_by] ||= []) << {var => :desc}
      self
    end

    ##
    # @example SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s
    #   query.select(:s).where([:s, :p, :o]).group_by(:s)
    #
    # @param  [Array<Symbol, String>] variables
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#groupby
    def group(*variables)
      options[:group_by] = variables
      self
    end

    alias_method :group_by, :group

    ##
    # @example SELECT DISTINCT ?s WHERE { ?s ?p ?o . }
    #   query.select(:s).distinct.where([:s, :p, :o])
    #
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modDuplicates
    def distinct(state = true)
      options[:distinct] = state
      self
    end

    ##
    # @example SELECT REDUCED ?s WHERE { ?s ?p ?o . }
    #   query.select(:s).reduced.where([:s, :p, :o])
    #
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modDuplicates
    def reduced(state = true)
      options[:reduced] = state
      self
    end

    ##
    # @example SELECT * WHERE { GRAPH ?g { ?s ?p ?o . } }
    #   query.select.graph(:g).where([:s, :p, :o])
    # @param  [RDF::Value] graph_uri_or_var
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#queryDataset
    def graph(graph_uri_or_var)
      options[:graph] = case graph_uri_or_var
        when Symbol then RDF::Query::Variable.new(graph_uri_or_var)
        when String then RDF::URI(graph_uri_or_var)
        when RDF::Value then graph_uri_or_var
        else raise ArgumentError
      end
      self
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } OFFSET 100
    #   query.select.where([:s, :p, :o]).offset(100)
    #
    # @param  [Integer, #to_i] start
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modOffset
    def offset(start)
      slice(start, nil)
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } LIMIT 10
    #   query.select.where([:s, :p, :o]).limit(10)
    #
    # @param  [Integer, #to_i] length
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#modResultLimit
    def limit(length)
      slice(nil, length)
    end

    ##
    # @example SELECT * WHERE { ?s ?p ?o . } OFFSET 100 LIMIT 10
    #   query.select.where([:s, :p, :o]).slice(100, 10)
    #
    # @param  [Integer, #to_i] start
    # @param  [Integer, #to_i] length
    # @return [Query]
    def slice(start, length)
      options[:offset] = start.to_i if start
      options[:limit] = length.to_i if length
      self
    end

    ##
    # @overload prefix(prefix: uri)
    #   @example PREFIX dc: <http://purl.org/dc/elements/1.1/> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT * WHERE \{ ?s ?p ?o . \}
    #     query.select.
    #       prefix(dc: RDF::URI("http://purl.org/dc/elements/1.1/")).
    #       prefix(foaf: RDF::URI("http://xmlns.com/foaf/0.1/")).
    #       where([:s, :p, :o])
    #
    #   @param [RDF::URI] uri
    #   @param [Symbol, String] prefix
    #   @return [Query]
    #
    # @overload prefix(string)
    #   @example PREFIX dc: <http://purl.org/dc/elements/1.1/> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT * WHERE \{ ?s ?p ?o . \}
    #     query.select.
    #       prefix("dc: <http://purl.org/dc/elements/1.1/>").
    #       prefix("foaf: <http://xmlns.com/foaf/0.1/>").
    #       where([:s, :p, :o])
    #
    #   @param [string] string
    #   @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#prefNames
    def prefix(*args)
      case args.length
      when 1
        (options[:prefixes] ||= []) << args[0]
      when 2
        (options[:prefixes] ||= []) << "#{args[0]}: <#{args[1]}>"
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1 or 2)"
      end
      self
    end

    ##
    # @example SELECT * WHERE \{ ?s ?p ?o . OPTIONAL \{ ?s a ?o . ?s \<http://purl.org/dc/terms/abstract\> ?o . \} \}
    #   query.select.where([:s, :p, :o]).
    #     optional([:s, RDF.type, :o], [:s, RDF::Vocab::DC.abstract, :o])
    #
    # The block form can be used for adding filters:
    #
    # @example ASK WHERE { ?s ?p ?o . OPTIONAL { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas'))} }
    #   query.ask.where([:s, :p, :o]).optional([:s, :p, :o]) do
    #     filter("regex(?s, 'Abiline, Texas')")
    #   end
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns
    #   splat of zero or more patterns followed by zero or more queries.
    # @yield [query]
    #   Yield form with or without argument; without an argument, evaluates within the query.
    # @yieldparam [SPARQL::Client::Query] query used for creating filters on the optional patterns.
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#optionals
    def optional(*patterns, &block)
      (options[:optionals] ||= []) << build_patterns(patterns)

      if block_given?
        # Steal options[:filters]
        query_filters = options[:filters]
        options[:filters] = []
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
        options[:optionals].last.concat(options[:filters])
        options[:filters] = query_filters
      end

      self
    end

    ##
    # @example SELECT * WHERE \{ ?book dc:title ?title \} UNION \{ ?book dc11:title ?title \}
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).
    #     union([:book, RDF::Vocab::DC11.title, :title])
    #
    # @example SELECT * WHERE \{ ?book dc:title ?title \} UNION \{ ?book dc11:title ?title . FILTER(langmatches(lang(?title), 'EN'))\}
    #   query1 = SPARQL::Client::Query.select.
    #     where([:book, RDF::Vocab::DC11.title, :title]).
    #     filter("langmatches(?title, 'en')")
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).union(query1)
    #
    # The block form can be used for more complicated queries, using the `select` form (note, use either block or argument forms, not both):
    #
    # @example SELECT * WHERE \{ ?book dc:title ?title \} UNION \{ ?book dc11:title ?title . FILTER(langmatches(lang(?title), 'EN'))\}
    #   query1 = SPARQL::Client::Query.select.where([:book, RDF::Vocab::DC11.title, :title]).filter("langmatches(?title, 'en')")
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).union do |q|
    #     q.select.
    #       where([:book, RDF::Vocab::DC11.title, :title]).
    #       filter("langmatches(?title, 'en')")
    #   end
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns
    #   splat of zero or more patterns followed by zero or more queries.
    # @yield [query]
    #   Yield form with or without argument; without an argument, evaluates within the query.
    # @yieldparam [SPARQL::Client::Query] query used for adding select clauses.
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#optionals
    def union(*patterns, &block)
      options[:unions] ||= []

      if block_given?
        raise ArgumentError, "#union requires either arguments or a block, not both." unless patterns.empty?
        # Evaluate calls in a new query instance
        query = self.class.select
        case block.arity
          when 1 then block.call(query)
          else query.instance_eval(&block)
        end
        options[:unions] << query
      elsif patterns.all? {|p| p.is_a?(SPARQL::Client::Query)}
        # With argument form, all must be patterns or queries
        options[:unions] += patterns
      elsif patterns.all? {|p| p.is_a?(Array)}
        # With argument form, all must be patterns, or queries
        options[:unions] << self.class.select.where(*patterns)
      else
        raise ArgumentError, "#union arguments are triple patters or queries, not both."
      end

      self
    end

    ##
    # @example SELECT * WHERE \{ ?book dc:title ?title . MINUS \{ ?book dc11:title ?title \} \}
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).
    #     minus([:book, RDF::Vocab::DC11.title, :title])
    #
    # @example SELECT * WHERE \{ ?book dc:title ?title MINUS \{ ?book dc11:title ?title . FILTER(langmatches(lang(?title), 'EN')) \} \}
    #   query1 = SPARQL::Client::Query.select.
    #     where([:book, RDF::Vocab::DC11.title, :title]).
    #     filter("langmatches(?title, 'en')")
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).minus(query1)
    #
    # The block form can be used for more complicated queries, using the `select` form (note, use either block or argument forms, not both):
    #
    # @example SELECT * WHERE \{ ?book dc:title ?title MINUS \{ ?book dc11:title ?title . FILTER(langmatches(lang(?title), 'EN'))\} \}
    #   query1 = SPARQL::Client::Query.select.where([:book, RDF::Vocab::DC11.title, :title]).filter("langmatches(?title, 'en')")
    #   query.select.where([:book, RDF::Vocab::DC.title, :title]).minus do |q|
    #     q.select.
    #       where([:book, RDF::Vocab::DC11.title, :title]).
    #       filter("langmatches(?title, 'en')")
    #   end
    #
    # @param  [Array<RDF::Query::Pattern, Array>] patterns
    #   splat of zero or more patterns followed by zero or more queries.
    # @yield [query]
    #   Yield form with or without argument; without an argument, evaluates within the query.
    # @yieldparam [SPARQL::Client::Query] query used for adding select clauses.
    # @return [Query]
    # @see    http://www.w3.org/TR/sparql11-query/#optionals
    def minus(*patterns, &block)
      options[:minuses] ||= []

      if block_given?
        raise ArgumentError, "#minus requires either arguments or a block, not both." unless patterns.empty?
        # Evaluate calls in a new query instance
        query = self.class.select
        case block.arity
          when 1 then block.call(query)
          else query.instance_eval(&block)
        end
        options[:minuses] << query
      elsif patterns.all? {|p| p.is_a?(SPARQL::Client::Query)}
        # With argument form, all must be patterns or queries
        options[:minuses] += patterns
      elsif patterns.all? {|p| p.is_a?(Array)}
        # With argument form, all must be patterns, or queries
        options[:minuses] << self.class.select.where(*patterns)
      else
        raise ArgumentError, "#minus arguments are triple patters or queries, not both."
      end

      self
    end

    ##
    # Specify inline data for a query
    #
    # @overload values
    #   Values returned from previous query.
    #
    #   @return [Array<Array(key, RDF::Value)>]
    #
    # @overload values(vars, *data)
    #   @example single variable with multiple values
    #     query.select
    #      .where([:s, RDF::URI('http://purl.org/dc/terms/title'), :title])
    #      .values(:title, "This title", "Another title")
    #
    #   @example multiple variables with multiple values
    #     query.select
    #      .where([:s, RDF::URI('http://purl.org/dc/terms/title'), :title],
    #             [:s, RDF.type, :type])
    #      .values([:type, :title],
    #              [RDF::URI('http://pcdm.org/models#Object'), "This title"],
    #              [RDF::URI('http://pcdm.org/models#Collection', 'Another title'])
    #
    #   @example multiple variables with UNDEF
    #     query.select
    #      .where([:s, RDF::URI('http://purl.org/dc/terms/title'), :title],
    #             [:s, RDF.type, :type])
    #      .values([:type, :title],
    #              [nil "This title"],
    #              [RDF::URI('http://pcdm.org/models#Collection', nil])
    #
    #   @param [Symbol, Array<Symbol>] vars
    #   @param [Array<RDF::Term, String, nil>] *data
    #   @return [Query]
    def values(*args)
      return @values if args.empty?
      vars, *data = *args
      vars = Array(vars).map {|var| RDF::Query::Variable.new(var)}
      if vars.length == 1
        # data may be a in array form or simple form
        if data.any? {|d| d.is_a?(Array)} && !data.all? {|d| d.is_a?(Array)}
          raise ArgumentError, "values data must all be in array form or all simple"
        end
        data = data.map {|d| Array(d)}
      end

      # Each data value must be an array with the same number of entries as vars
      unless data.all? {|d| d.is_a?(Array) && d.all? {|dd| dd.is_a?(RDF::Value) || dd.is_a?(String) || dd.nil?}}
        raise ArgumentError, "values data must each be an array of terms, strings, or nil"
      end

      # Turn strings into Literals
      data = data.map do |d|
        d.map do |nil_literal_or_term|
          case nil_literal_or_term
          when nil then nil
          when String then RDF::Literal(nil_literal_or_term)
          when RDF::Value then graph_uri_or_var
          else raise ArgumentError
          end
        end
      end
      options[:values] = [vars, *data]
      self
    end

    ##
    # @return expects_statements?
    def expects_statements?
      [:construct, :describe].include?(form)
    end

    ##
    # @private 
    def build_patterns(patterns)
      patterns.map {|pattern| RDF::Query::Pattern.from(pattern)}
    end

    ##
    # @example ASK WHERE { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas')) }
    #   query.ask.where([:s, :p, :o]).filter("regex(?s, 'Abiline, Texas')")
    # @return [Query]
    def filter(string)
      ((options[:filters] ||= []) << Filter.new(string)) if string and not string.empty?
      self
    end

    ##
    # @return [Boolean]
    def true?
      case result
        when TrueClass, FalseClass then result
        when RDF::Literal::Boolean then result.true?
        when Enumerable then !result.empty?
        else false
      end
    end

    ##
    # @return [Boolean]
    def false?
      !true?
    end

    ##
    # @return [Enumerable<RDF::Query::Solution>]
    def solutions
      result
    end

    ##
    # @yield  [statement]
    # @yieldparam [RDF::Statement]
    # @return [Enumerator]
    def each_statement(&block)
      result.each_statement(&block)
    end

    # Enumerates over each matching query solution.
    #
    # @yield  [solution]
    # @yieldparam [RDF::Query::Solution] solution
    # @return [Enumerator]
    def each_solution(&block)
      @solutions = result
      super
    end

    ##
    # @return [Object]
    def result
      @result ||= execute
    end

    ##
    # @return [Object]
    def execute
      raise NotImplementedError
    end

    ##
    # Returns the string representation of this query.
    #
    # @return [String]
    def to_s
      buffer = [form.to_s.upcase]

      case form
        when :select, :describe
          only_count = values.empty? && options[:count]
          buffer << 'DISTINCT' if options[:distinct] and not only_count
          buffer << 'REDUCED'  if options[:reduced]
          buffer << ((values.empty? and not options[:count]) ? '*' : values.map { |v| SPARQL::Client.serialize_value(v[1]) }.join(' '))
          if options[:count]
            options[:count].each do |var, count|
              buffer << '( COUNT(' + (options[:distinct] ? 'DISTINCT ' : '') +
                (var.is_a?(String) ? var : "?#{var}") + ') AS ' + (count.is_a?(String) ? count : "?#{count}") + ' )'
            end
          end
        when :construct
          buffer << '{'
          buffer += SPARQL::Client.serialize_patterns(options[:template])
          buffer << '}'
      end

      buffer << "FROM #{SPARQL::Client.serialize_value(options[:from])}" if options[:from]

      unless patterns.empty? && form == :describe
        buffer += self.to_s_ggp.unshift('WHERE')
      end

      options.fetch(:unions, []).each do |query|
        buffer += query.to_s_ggp.unshift('UNION')
      end

      if options[:group_by]
        buffer << 'GROUP BY'
        buffer += options[:group_by].map { |var| var.is_a?(String) ? var : "?#{var}" }
      end

      if options[:order_by]
        buffer << 'ORDER BY'
        options[:order_by].map { |elem|
          case elem
            # .order_by({ :var1 => :asc, :var2 => :desc})
            when Hash
              elem.each { |key, val|
                # check provided values
                if !key.is_a?(Symbol)
                  raise ArgumentError, 'keys of hash argument must be a Symbol'
                elsif !val.is_a?(Symbol) || (val != :asc && val != :desc)
                  raise ArgumentError, 'values of hash argument must either be `:asc` or `:desc`'
                end
                buffer << "#{val == :asc ? 'ASC' : 'DESC'}(?#{key})"
              }
            # .order_by([:var1, :asc], [:var2, :desc])
            when Array
              # check provided values
              if elem.length != 2
                raise ArgumentError, 'array argument must specify two elements'
              elsif !elem[0].is_a?(Symbol)
                raise ArgumentError, '1st element of array argument must contain a Symbol'
              elsif !elem[1].is_a?(Symbol) || (elem[1] != :asc && elem[1] != :desc)
                raise ArgumentError, '2nd element of array argument must either be `:asc` or `:desc`'
              end
              buffer << "#{elem[1] == :asc ? 'ASC' : 'DESC'}(?#{elem[0]})"
            # .order_by(:var1, :var2)
            when Symbol
              buffer << "?#{elem}"
            # .order_by('ASC(?var1) DESC(?var2)')
            when String
              buffer << elem
            else
              raise ArgumentError, 'argument provided to `order()` must either be an Array, Symbol or String'
          end
        }
      end

      buffer << "OFFSET #{options[:offset]}" if options[:offset]
      buffer << "LIMIT #{options[:limit]}"   if options[:limit]
      options[:prefixes].reverse.each { |e| buffer.unshift("PREFIX #{e}") } if options[:prefixes]

      buffer.join(' ')
    end

    # Serialize a Group Graph Pattern
    # @private
    def to_s_ggp
      buffer = ["{"]

      if options[:graph]
        buffer << 'GRAPH ' + SPARQL::Client.serialize_value(options[:graph])
        buffer << '{'
      end

      @subqueries.each do |sq|
        buffer << "{ #{sq.to_s} } ."
      end

      buffer += SPARQL::Client.serialize_patterns(patterns)
      if options[:optionals]
        options[:optionals].each do |patterns|
          buffer << 'OPTIONAL {'
          buffer += SPARQL::Client.serialize_patterns(patterns)
          buffer << '}'
        end
      end
      if options[:filters]
        buffer += options[:filters].map(&:to_s)
      end
      if options[:values]
        vars = options[:values].first.map {|var| SPARQL::Client.serialize_value(var)}
        buffer << "VALUES (#{vars.join(' ')}) {"
        options[:values][1..-1].each do |data_block_value|
          buffer << '('
          buffer << data_block_value.map do |value|
            value.nil? ? 'UNDEF' : SPARQL::Client.serialize_value(value)
          end.join(' ')
          buffer << ')'
        end
        buffer << '}'
      end
      if options[:graph]
        buffer << '}' # GRAPH
      end

      options.fetch(:minuses, []).each do |query|
        buffer += query.to_s_ggp.unshift('MINUS')
      end

      buffer << '}'
      buffer
    end

    ##
    # Outputs a developer-friendly representation of this query to `stderr`.
    #
    # @return [void]
    def inspect!
      warn(inspect)
      self
    end

    ##
    # Returns a developer-friendly representation of this query.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, to_s)
    end

    # Allow Filters to be 
    class Filter < SPARQL::Client::QueryElement
      def initialize(*args)
        super
      end

      def to_s
        "FILTER(#{elements.join(' ')})"
      end
    end
  end
end
