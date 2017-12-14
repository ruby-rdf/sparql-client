class SPARQL::Client
  ##
  # SPARQL 1.1 Update operation builders.
  module Update
    ##
    # Insert statements into the graph
    #
    # @example INSERT DATA \{ <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\}
    #   data = RDF::Graph.new do |graph|
    #     graph << [RDF::URI('http://example.org/jhacker'), RDF::Vocab::FOAF.name, "J. Random Hacker"]
    #   end
    #   insert_data(data)
    #
    # @example INSERT DATA \{ GRAPH <http://example.org/> \{\}\}
    #   insert_data(RDF::Graph.new, :graph => 'http://example.org/')
    #   insert_data(RDF::Graph.new).graph('http://example.org/')
    #
    # @param (see InsertData#initialize)
    def self.insert_data(*arguments)
      InsertData.new(*arguments)
    end

    ##
    # Delete statements from the graph
    #
    # @example DELETE DATA \{ <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\}
    #   data = RDF::Graph.new do |graph|
    #     graph << [RDF::URI('http://example.org/jhacker'), RDF::Vocab::FOAF.name, "J. Random Hacker"]
    #   end
    #   delete_data(data)
    #
    # @example DELETE DATA \{ GRAPH <http://example.org/> \{\}\}
    #   delete_data(RDF::Graph.new, :graph => 'http://example.org/')
    #   delete_data(RDF::Graph.new).graph('http://example.org/')
    #
    # @param (see DeleteData#initialize)
    def self.delete_data(*arguments)
      DeleteData.new(*arguments)
    end

    ##
    # Load statements into the graph
    #
    # @example LOAD <http://example.org/data.rdf>
    #   load(RDF::URI(http://example.org/data.rdf))
    #
    # @example LOAD SILENT <http://example.org/data.rdf>
    #   load(RDF::URI(http://example.org/data.rdf)).silent
    #   load(RDF::URI(http://example.org/data.rdf), silent: true)
    #
    # @example LOAD <http://example.org/data.rdf> INTO <http://example.org/data.rdf>
    #   load(RDF::URI(http://example.org/data.rdf)).into(RDF::URI(http://example.org/data.rdf))
    #   load(RDF::URI(http://example.org/data.rdf), into: RDF::URI(http://example.org/data.rdf))
    #
    # @param (see Load#initialize)
    def self.load(*arguments)
      Load.new(*arguments)
    end

    ##
    # Clear the graph
    #
    # @example CLEAR GRAPH <http://example.org/data.rdf>
    #   clear.graph(RDF::URI(http://example.org/data.rdf))
    #   clear(:graph, RDF::URI(http://example.org/data.rdf))
    #
    # @example CLEAR DEFAULT
    #   clear.default
    #   clear(:default)
    #
    # @example CLEAR NAMED
    #   clear.named
    #   clear(:named)
    #
    # @example CLEAR ALL
    #   clear.all
    #   clear(:all)
    #
    # @example CLEAR SILENT ALL
    #   clear.all.silent
    #   clear(:all, silent: true)
    #
    # @param (see Clear#initialize)
    def self.clear(*arguments)
      Clear.new(*arguments)
    end

    ##
    # Create a graph
    #
    # @example CREATE GRAPH <http://example.org/data.rdf>
    #   create(RDF::URI(http://example.org/data.rdf))
    #
    # @example CREATE SILENT GRAPH <http://example.org/data.rdf>
    #   create(RDF::URI(http://example.org/data.rdf)).silent
    #   create(RDF::URI(http://example.org/data.rdf), silent: true)
    #
    # @param (see Create#initialize)
    def self.create(*arguments)
      Create.new(*arguments)
    end

    ##
    # Drop a graph
    #
    # @example DROP GRAPH <http://example.org/data.rdf>
    #   drop.graph(RDF::URI(http://example.org/data.rdf))
    #   drop(:graph, RDF::URI(http://example.org/data.rdf))
    #
    # @example DROP DEFAULT
    #   drop.default
    #   drop(:default)
    #
    # @example DROP NAMED
    #   drop.named
    #   drop(:named)
    #
    # @example DROP ALL
    #   drop.all
    #   drop(:all)
    #
    # @example DROP ALL SILENT
    #   drop.all.silent
    #   drop(:all, silent: true)
    #
    # @param (see Drop#initialize)
    def self.drop(*arguments)
      Drop.new(*arguments)
    end

    class Operation
      attr_reader :options

      def initialize(*arguments)
        @options = arguments.last.is_a?(Hash) ? arguments.pop.dup : {}
        unless arguments.empty?
          send(arguments.shift, *arguments)
        end
      end

      ##
      # Generic Update always returns statements
      #
      # @return [true]
      def expects_statements?
        true
      end

      ##
      # Set `silent` option
      def silent
        self.options[:silent] = true
        self
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#insertData
    class InsertData < Operation
      # @return [RDF::Enumerable]
      attr_reader :data

      ##
      # Insert statements into the graph
      #
      # @example INSERT DATA \{ <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\}
      #   data = RDF::Graph.new do |graph|
      #     graph << [RDF::URI('http://example.org/jhacker'), RDF::Vocab::FOAF.name, "J. Random Hacker"]
      #   end
      #   insert_data(data)
      #   
      # @param [Array<RDF::Statement>, RDF::Enumerable] data
      # @param  [Hash{Symbol => Object}] options
      def initialize(data, options = {})
        @data = data
        super(options)
      end

      ##
      # Cause data to be inserted into the graph specified by `uri`
      #
      # @param [RDF::URI] uri
      # @return [self]
      def graph(uri)
        self.options[:graph] = uri
        self
      end

      ##
      # InsertData always returns result set
      #
      # @return [true]
      def expects_statements?
        false
      end

      def to_s
        query_text = 'INSERT DATA {'
        query_text += ' GRAPH ' + SPARQL::Client.serialize_uri(self.options[:graph]) + ' {' if self.options[:graph]
        query_text += "\n"
        query_text += RDF::NTriples::Writer.buffer { |writer| @data.each { |d| writer << d } }
        query_text += '}' if self.options[:graph]
        query_text += "}\n"
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#deleteData
    class DeleteData < Operation
      # @return [RDF::Enumerable]
      attr_reader :data

      ##
      # Delete statements from the graph
      #
      # @example DELETE DATA \{ <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\}
      #   data = RDF::Graph.new do |graph|
      #     graph << [RDF::URI('http://example.org/jhacker'), RDF::Vocab::FOAF.name, "J. Random Hacker"]
      #   end
      #   delete_data(data)
      #   
      # @param [Array<RDF::Statement>, RDF::Enumerable] data
      # @param  [Hash{Symbol => Object}] options
      def initialize(data, options = {})
        @data = data
        super(options)
      end

      ##
      # Cause data to be deleted from the graph specified by `uri`
      #
      # @param [RDF::URI] uri
      # @return [self]
      def graph(uri)
        self.options[:graph] = uri
        self
      end

      def to_s
        query_text = 'DELETE DATA {'
        query_text += ' GRAPH ' + SPARQL::Client.serialize_uri(self.options[:graph]) + ' {' if self.options[:graph]
        query_text += "\n"
        query_text += RDF::NTriples::Writer.buffer { |writer| @data.each { |d| writer << d } }
        query_text += '}' if self.options[:graph]
        query_text += "}\n"
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#deleteInsert
    class DeleteInsert < Operation
      attr_reader :insert_graph
      attr_reader :delete_graph
      attr_reader :where_graph

      def initialize(_delete_graph, _insert_graph = nil, _where_graph = nil, options = {})
        @delete_graph = _delete_graph
        @insert_graph = _insert_graph
        @where_graph = _where_graph
        super(options)
      end

      ##
      # Cause data to be deleted and inserted from the graph specified by `uri`
      #
      # @param [RDF::URI] uri
      # @return [self]
      def graph(uri)
        self.options[:graph] = uri
        self
      end

      def to_s
        buffer = []

        if self.options[:graph]
          buffer << "WITH"
          buffer << SPARQL::Client.serialize_uri(self.options[:graph])
        end
        if delete_graph and !delete_graph.empty?
          serialized_delete = SPARQL::Client.serialize_patterns delete_graph, true
          buffer << "DELETE {\n"
          buffer += serialized_delete
          buffer << "}\n"
        end
        if insert_graph and !insert_graph.empty?
          buffer << "INSERT {\n"
          buffer += SPARQL::Client.serialize_patterns insert_graph, true
          buffer << "}\n"
        end
          buffer << "WHERE {\n"
        if where_graph
          buffer += SPARQL::Client.serialize_patterns where_graph, true
        elsif serialized_delete
          buffer += serialized_delete
        end
        buffer << "}\n"
        buffer.join(' ')
      end

    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#load
    class Load < Operation
      attr_reader :from
      attr_reader :into


      ##
      # Load statements into the graph
      #
      # @example LOAD <http://example.org/data.rdf>
      #   load(RDF::URI(http://example.org/data.rdf))
      #
      # @example LOAD SILENT<http://example.org/data.rdf>
      #   load(RDF::URI(http://example.org/data.rdf)).silent
      #   load(RDF::URI(http://example.org/data.rdf), silent: true)
      #
      # @example LOAD <http://example.org/data.rdf> INTO <http://example.org/data.rdf>
      #   load(RDF::URI(http://example.org/data.rdf)).into(RDF::URI(http://example.org/data.rdf))
      #   load(RDF::URI(http://example.org/data.rdf), into: RDF::URI(http://example.org/data.rdf))
      # @param [RDF::URI] from
      # @param  [Hash{Symbol => Object}] options
      # @option [RDF::URI] :into
      # @option [Boolean] :silent
      def initialize(from, options = {})
        options = options.dup
        @from = RDF::URI(from)
        @into = RDF::URI(options.delete(:into)) if options[:into]
        super(options)
      end

      ##
      # Cause data to be loaded into graph specified by `uri`
      #
      # @param [RDF::URI] uri
      # @return [self]
      def into(uri)
        @into = RDF::URI(uri)
        self
      end

      def to_s
        query_text = 'LOAD '
        query_text += 'SILENT ' if self.options[:silent]
        query_text += SPARQL::Client.serialize_uri(@from)
        query_text += ' INTO GRAPH ' + SPARQL::Client.serialize_uri(@into) if @into
        query_text
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#clear
    class Clear < Operation
      attr_reader :uri

      ##
      # Cause data to be cleared from graph specified by `uri`
      #
      # @param [RDF::URI] uri
      # @return [self]
      def graph(uri)
        @what, @uri = :graph, uri
        self
      end

      ##
      # Cause data to be cleared from the default graph
      #
      # @return [self]
      def default
        @what = :default
        self
      end

      ##
      # Cause data to be cleared from named graphs
      #
      # @return [self]
      def named
        @what = :named
        self
      end

      ##
      # Cause data to be cleared from all graphs
      #
      # @return [self]
      def all
        @what = :all
        self
      end

      ##
      # Clear always returns statements
      #
      # @return [false]
      def expects_statements?
        false
      end

      def to_s
        query_text = 'CLEAR '
        query_text += 'SILENT ' if self.options[:silent]
        case @what.to_sym
          when :graph   then query_text += 'GRAPH ' + SPARQL::Client.serialize_uri(@uri)
          when :default then query_text += 'DEFAULT'
          when :named   then query_text += 'NAMED'
          when :all     then query_text += 'ALL'
          else raise ArgumentError, "invalid CLEAR operation: #{@what.inspect}"
        end
        query_text
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#create
    class Create < Operation
      attr_reader :uri

      # @param  [Hash{Symbol => Object}] options
      def initialize(uri, options = {})
        @uri = RDF::URI(uri)
        super(options)
      end

      def to_s
        query_text = 'CREATE '
        query_text += 'SILENT ' if self.options[:silent]
        query_text += 'GRAPH ' + SPARQL::Client.serialize_uri(@uri)
        query_text
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#drop
    class Drop < Clear
      def to_s
        query_text = 'DROP '
        query_text += 'SILENT ' if self.options[:silent]
        case @what.to_sym
          when :graph   then query_text += 'GRAPH ' + SPARQL::Client.serialize_uri(@uri)
          when :default then query_text += 'DEFAULT'
          when :named   then query_text += 'NAMED'
          when :all     then query_text += 'ALL'
          else raise ArgumentError, "invalid DROP operation: #{@what.inspect}"
        end
        query_text
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#copy
    class Copy < Operation
      def to_s
        # TODO
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#move
    class Move < Operation
      def to_s
        # TODO
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#add
    class Add < Operation
      def to_s
        # TODO
      end
    end
  end # Update
end # SPARQL::Client
