class SPARQL::Client
  ##
  # SPARQL 1.1 Update operation builders.
  module Update
    def self.insert_data(*arguments)
      InsertData.new(*arguments)
    end

    def self.delete_data(*arguments)
      DeleteData.new(*arguments)
    end

    def self.load(*arguments)
      Load.new(*arguments)
    end

    def self.clear(*arguments)
      Clear.new(*arguments)
    end

    def self.create(*arguments)
      Create.new(*arguments)
    end

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
      # Update always returns statements
      #
      # @return expects_statements?
      def expects_statements?
        true
      end

      def silent
        self.options[:silent] = true
        self
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#insertData
    class InsertData < Operation
      attr_reader :data

      def initialize(data, options = {})
        @data = data
        super(options)
      end

      def graph(uri)
        self.options[:graph] = uri
        self
      end

      ##
      # Update always returns statements
      #
      # @return expects_statements?
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
      attr_reader :data

      def initialize(data, options = {})
        @data = data
        super(options)
      end

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
          serialized_delete = SPARQL::Client.serialize_patterns delete_graph
          buffer << "DELETE {\n"
          buffer += serialized_delete
          buffer << "}\n"
        end
        if insert_graph and !insert_graph.empty?
          buffer << "INSERT {\n"
          buffer += SPARQL::Client.serialize_patterns insert_graph
          buffer << "}\n"
        end
          buffer << "WHERE {\n"
        if where_graph
          buffer += SPARQL::Client.serialize_patterns where_graph
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

      def initialize(from, options = {})
        options = options.dup
        @from = RDF::URI(from)
        @into = RDF::URI(options.delete(:into)) if options[:into]
        super(options)
      end

      def into(url)
        @into = RDF::URI(url)
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

      def graph(uri)
        @what, @uri = :graph, uri
        self
      end

      def default
        @what = :default
        self
      end

      def named
        @what = :named
        self
      end

      def all
        @what = :all
        self
      end

      ##
      # Update always returns statements
      #
      # @return expects_statements?
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
