module SPARQL; class Client
  ##
  # A read-only repository view of a SPARQL endpoint.
  #
  # @see RDF::Repository
  class Repository < RDF::Repository
    # @return [SPARQL::Client]
    attr_reader :client

    ##
    # @param  [String, #to_s]          endpoint
    # @param  [Hash{Symbol => Object}] options
    def initialize(endpoint, options = {})
      @options = options.dup
      @update_client = SPARQL::Client.new(options.delete(:update_endpoint), options) if options[:update_endpoint]
      @client  = SPARQL::Client.new(endpoint, options)
    end

    ##
    # Returns the client for the update_endpoint if specified, otherwise the
    # {client}.
    #
    # @return [SPARQL::Client]
    def update_client
      @update_client || @client
    end

    # Enumerates each RDF statement in this repository.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @see    RDF::Repository#each
    def each(&block)
      client.construct([:s, :p, :o]).where([:s, :p, :o]).each_statement(&block)
    end

    ##
    # @private
    # @see RDF::Enumerable#supports?
    def supports?(feature)
      case feature.to_sym
        # statement contexts / named graphs
        when :context   then false
        when :inference then false  # forward-chaining inference
        when :validity  then false
        else false
      end
    end

    ##
    # Returns `true` if this repository contains the given subject.
    #
    # @param  [RDF::Resource] subject
    # @return [Boolean]
    # @see    RDF::Repository#has_subject?
    def has_subject?(subject)
      client.ask.whether([subject, :p, :o]).true?
    end

    ##
    # Returns `true` if this repository contains the given predicate.
    #
    # @param  [RDF::URI] predicate
    # @return [Boolean]
    # @see    RDF::Repository#has_predicate?
    def has_predicate?(predicate)
      client.ask.whether([:s, predicate, :o]).true?
    end

    ##
    # Returns `true` if this repository contains the given object.
    #
    # @param  [RDF::Value] object
    # @return [Boolean]
    # @see    RDF::Repository#has_object?
    def has_object?(object)
      client.ask.whether([:s, :p, object]).true?
    end

    ##
    # Iterates over each subject in this repository.
    #
    # @yield  [subject]
    # @yieldparam [RDF::Resource] subject
    # @return [Enumerator]
    # @see    RDF::Repository#each_subject?
    def each_subject(&block)
      if block_given?
        client.select(:s, :distinct => true).where([:s, :p, :o]).each_solution { |solution| block.call(solution[:s]) }
      end
      enum_subject
    end

    ##
    # Iterates over each predicate in this repository.
    #
    # @yield  [predicate]
    # @yieldparam [RDF::URI] predicate
    # @return [Enumerator]
    # @see    RDF::Repository#each_predicate?
    def each_predicate(&block)
      if block_given?
        client.select(:p, :distinct => true).where([:s, :p, :o]).each_solution { |solution| block.call(solution[:p]) }
      end
      enum_predicate
    end

    ##
    # Iterates over each object in this repository.
    #
    # @yield  [object]
    # @yieldparam [RDF::Value] object
    # @return [Enumerator]
    # @see    RDF::Repository#each_object?
    def each_object(&block)
      if block_given?
        client.select(:o, :distinct => true).where([:s, :p, :o]).each_solution { |solution| block.call(solution[:o]) }
      end
      enum_object
    end

    ##
    # Returns `true` if this repository contains the given `triple`.
    #
    # @param  [Array<RDF::Resource, RDF::URI, RDF::Value>] triple
    # @return [Boolean]
    # @see    RDF::Repository#has_triple?
    def has_triple?(triple)
      client.ask.whether(triple.to_a[0...3]).true?
    end

    ##
    # Returns `true` if this repository contains the given `statement`.
    #
    # @param  [RDF::Statement] statement
    # @return [Boolean]
    # @see    RDF::Repository#has_statement?
    def has_statement?(statement)
      has_triple?(statement.to_triple)
    end

    ##
    # Returns the number of statements in this repository.
    #
    # @return [Integer]
    # @see    RDF::Repository#count?
    def count
      begin
        binding = client.query("SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }").first.to_hash
        binding[:count].value.to_i rescue 0
      rescue SPARQL::Client::MalformedQuery => e
        # SPARQL 1.0 does not include support for aggregate functions:
        count = 0
        each_statement { count += 1 } # TODO: optimize this
        count
      end
    end

    alias_method :size,   :count
    alias_method :length, :count

    ##
    # Returns `true` if this repository contains no statements.
    #
    # @return [Boolean]
    # @see    RDF::Repository#empty?
    def empty?
      client.ask.whether([:s, :p, :o]).false?
    end

    ##
    # Returns `false` to indicate that this is a read-only repository.
    #
    # @return [Boolean]
    # @see    RDF::Mutable#mutable?
    def writable?
      true
    end

    ##
    # @private
    # @see RDF::Mutable#clear
    def clear_statements
      update_client.clear(:all)
    end

    ##
    # Deletes RDF statements from `self`.
    # If any statement contains a {Query::Variable}, it is
    # considered to be a pattern, and used to query
    # self to find matching statements to delete.
    #
    # @param  [Enumerable<RDF::Statement>] statements
    # @raise  [TypeError] if `self` is immutable
    # @return [Mutable]
    def delete(*statements)
      delete_statements(statements) unless statements.empty?
      return self
    end

    protected

    ##
    # Queries `self` using the given basic graph pattern (BGP) query,
    # yielding each matched solution to the given block.
    #
    # Overrides Queryable::query_execute to use SPARQL::Client::query
    #
    # @param  [RDF::Query] query
    #   the query to execute
    # @param  [Hash{Symbol => Object}] options ({})
    #   Any other options passed to `query.execute`
    # @yield  [solution]
    # @yieldparam  [RDF::Query::Solution] solution
    # @yieldreturn [void] ignored
    # @return [void] ignored
    # @see    RDF::Queryable#query
    # @see    RDF::Query#execute
    def query_execute(query, options = {}, &block)
      return nil unless block_given?
      q = SPARQL::Client::Query.select(query.variables).where(*query.patterns)
      client.query(q, options).each do |solution|
        yield solution
      end
    end

    ##
    # Queries `self` for RDF statements matching the given `pattern`.
    #
    # @example
    #     repository.query([nil, RDF::DOAP.developer, nil])
    #     repository.query(:predicate => RDF::DOAP.developer)
    #
    # @fixme This should use basic SPARQL query mechanism.
    #
    # @param  [Pattern] pattern
    # @see    RDF::Queryable#query_pattern
    # @yield  [statement]
    # @yieldparam [Statement]
    # @return [Enumerable<Statement>]
    def query_pattern(pattern, &block)
      pattern = pattern.dup
      pattern.subject   ||= RDF::Query::Variable.new
      pattern.predicate ||= RDF::Query::Variable.new
      pattern.object    ||= RDF::Query::Variable.new
      pattern.initialize!
      query = client.construct(pattern).where(pattern)

      if block_given?
        query.each_statement(&block)
      else
        query.solutions.to_a.extend(RDF::Enumerable, RDF::Queryable)
      end
    end

    ##
    # Deletes the given RDF statements from the underlying storage.
    #
    # Overridden here to use SPARQL/UPDATE
    #
    # @param  [RDF::Enumerable] statements
    # @return [void]
    def delete_statements(statements)

      constant = statements.all? do |value|
        # needs to be flattened... urgh
        !value.respond_to?(:each_statement) && begin
          statement = RDF::Statement.from(value)
          statement.constant? && !statement.has_blank_nodes?
        end
      end

      if constant
        update_client.delete_data(statements)
      else
        update_client.delete_insert(statements)
      end
    end

    ##
    # Inserts the given RDF statements into the underlying storage or output
    # stream.
    #
    # Overridden here to use SPARQL/UPDATE
    #
    # @param  [RDF::Enumerable] statements
    # @return [void]
    # @since  0.1.6
    def insert_statements(statements)
      update_client.insert_data(statements)
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    def insert_statement(statement)
      update_client.insert_data([statement])
    end

  end
end; end
