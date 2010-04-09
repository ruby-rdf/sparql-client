require 'rdf'
require 'enumerator'
require 'addressable/uri'
require 'sparql/client'

module SPARQL ; class Client
  class Repository < ::RDF::Repository

    def initialize(endpoint)
      @client = SPARQL::Client.new(endpoint)
    end

    # Run an ASK query
    # @param [String] query
    #
    # @return [Boolean]
    # @private
    def ask(query)
      @client.query(query)
    end

    # Run a construct query
    # @param [String] query
    # @param [&block]
    #
    # Returns an RDF::Reader instance which iterates over the results.
    # @see RDF::Reader#each_statement
    # @private
    def construct(query, &block)
      @client.query(query).each_statement(&block)
    end

    # Run a select query
    # @param [String] query
    # @param [&block]
    # @yieldparam [RDF::Value] value
    #
    # Returns an array of RDF::Query::Solutions or yields the first value from each binding to a block.
    # Would require refactoring if a query needed to use more than one binding result
    # @private
    def select(query,&block)
      result = @client.query(query)
      case block_given?
        when true
          result.each do |bindings|
            yield bindings.each_value.to_a.first
          end
        when false
          return result
      end
    end

    ##
    # Enumerates each RDF statement in this repository.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [Enumerator]
    # @see [RDF::Repository#each]
    def each(&block)
      construct("CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }", &block)
    end

    ##
    # Returns true if this repository contains the given subject.
    #
    # @param  [RDF::Resource]
    # @return [Boolean]
    # @see [RDF::Repository#has_subject?]
    def has_subject?(subject)
      ask "ASK { #{RDF::NTriples.serialize(subject)} ?p ?o }"
    end

    ##
    # Returns true if this repository contains the given predicate.
    #
    # @param  [RDF::Resource]
    # @return [Boolean]
    # @see [RDF::Repository#has_predicate?]
    def has_predicate?(predicate)
      ask "ASK { ?s #{RDF::NTriples.serialize(predicate)} ?o }"
    end

    ##
    # Returns true if this repository contains the given object.
    #
    # @param  [RDF::Resource]
    # @return [Boolean]
    # @see [RDF::Repository#has_object?]
    def has_object?(object)
      ask "ASK { ?s ?p #{RDF::NTriples.serialize(object)}}"
    end

    ##
    # Iterate over each subject in this repository
    #
    # @yieldparam [RDF::Resource]
    # @return [Enumerable::Enumerator, nil]
    # @see [RDF::Repository#each_subject?]
    def each_subject(&block)
      return ::Enumerable::Enumerator.new(self,:each_subject) unless block_given?
      ret = select("SELECT DISTINCT ?s WHERE { ?s ?p ?o }", &block)
    end

    ##
    # Iterate over each predicate in this repository
    #
    # @yieldparam [RDF::Resource]
    # @return [Enumerable::Enumerator, nil]
    # @see [RDF::Repository#each_predicate?]
    def each_predicate(&block)
      return ::Enumerable::Enumerator.new(self,:each_predicate) unless block_given?
      select("SELECT DISTINCT ?p WHERE { ?s ?p ?o }", &block)
    end

    ##
    # Iterate over each object in this repository
    #
    # @yieldparam [RDF::Resource]
    # @return [Enumerable::Enumerator, nil]
    # @see [RDF::Repository#each_object?]
    def each_object(&block)
      return ::Enumerable::Enumerator.new(self,:each_object) unless block_given?
      select("SELECT DISTINCT ?o WHERE { ?s ?p ?o }", &block)
    end

    ##
    # Returns true if this repository contains the given triple
    #
    # @param [Array]
    # @return [Boolean]
    # @see [RDF::Repository#has_triple?]
    def has_triple?(array)
      subject   = RDF::NTriples.serialize(array[0])  
      predicate = RDF::NTriples.serialize(array[1])  
      object    = RDF::NTriples.serialize(array[2])
      ask "ASK { #{subject} #{predicate} #{object} }"
    end

    ##
    # Returns true if this repository contains the given statement
    #
    # @param [RDF::Statement]
    # @return [Boolean]
    # @see [RDF::Repository#has_statement?]
    def has_statement?(statement)
      has_triple?(statement.to_triple)
    end

    ##
    # Returns the number of statements in this repository
    #
    # @return [Integer]
    # @see [RDF::Repository#count?]
    def count
      begin
        binding = select("SELECT COUNT(*) WHERE { ?s ?p ?o }").first.to_hash
        binding[binding.keys.first].value.to_i
      rescue SPARQL::Client::MalformedQuery => e
        # SPARQL 1.0 does not include support for aggregate functions:
        count = 0
        each_statement { count += 1 } # TODO: optimize this
        count
      end
    end
    alias_method :size, :count
    alias_method :length, :count

    ##
    # Returns true if this repository has no statements
    #
    # @return [Boolean]
    # @see [RDF::Repository#empty?]
    def empty?
      !(ask "ASK { ?s ?p ?o }")
    end

    # @see RDF::Mutable#insert_statement
    def insert_statement(statement)
      raise NotImplementedError
    end

    # @see RDF::Mutable#delete_statement
    def delete_statement(statement)
      raise NotImplementedError
    end

  end
end; end
