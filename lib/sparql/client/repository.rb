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
      @client  = SPARQL::Client.new(endpoint, options)
    end

    ##
    # Enumerates each RDF statement in this repository.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [Enumerator]
    # @see    RDF::Repository#each
    def each(&block)
      unless block_given?
        RDF::Enumerator.new(self, :each)
      else
        client.construct([:s, :p, :o]).where([:s, :p, :o]).each_statement(&block)
      end
    end

    ##
    # Returns `true` if this repository contains the given subject.
    #
    # @param  [RDF::Resource]
    # @return [Boolean]
    # @see    RDF::Repository#has_subject?
    def has_subject?(subject)
      client.ask.whether([subject, :p, :o]).true?
    end

    ##
    # Returns `true` if this repository contains the given predicate.
    #
    # @param  [RDF::URI]
    # @return [Boolean]
    # @see    RDF::Repository#has_predicate?
    def has_predicate?(predicate)
      client.ask.whether([:s, predicate, :o]).true?
    end

    ##
    # Returns `true` if this repository contains the given object.
    #
    # @param  [RDF::Value]
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
      unless block_given?
        RDF::Enumerator.new(self, :each_subject)
      else
        client.select(:s, :distinct => true).where([:s, :p, :o]).each { |solution| block.call(solution[:s]) }
      end
    end

    ##
    # Iterates over each predicate in this repository.
    #
    # @yield  [predicate]
    # @yieldparam [RDF::URI] predicate
    # @return [Enumerator]
    # @see    RDF::Repository#each_predicate?
    def each_predicate(&block)
      unless block_given?
        RDF::Enumerator.new(self, :each_predicate)
      else
        client.select(:p, :distinct => true).where([:s, :p, :o]).each { |solution| block.call(solution[:p]) }
      end
    end

    ##
    # Iterates over each object in this repository.
    #
    # @yield  [object]
    # @yieldparam [RDF::Value] object
    # @return [Enumerator]
    # @see    RDF::Repository#each_object?
    def each_object(&block)
      unless block_given?
        RDF::Enumerator.new(self, :each_object)
      else
        client.select(:o, :distinct => true).where([:s, :p, :o]).each { |solution| block.call(solution[:o]) }
      end
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
        binding = client.query("SELECT COUNT(*) WHERE { ?s ?p ?o }").first.to_hash
        binding[binding.keys.first].value.to_i
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
    # Queries `self` for RDF statements matching the given `pattern`.
    #
    # @example
    #     repository.query([nil, RDF::DOAP.developer, nil])
    #     repository.query(:predicate => RDF::DOAP.developer)
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
    # Returns `false` to indicate that this is a read-only repository.
    #
    # @return [Boolean]
    # @see    RDF::Mutable#mutable?
    def writable?
      false
    end
  end
end; end
