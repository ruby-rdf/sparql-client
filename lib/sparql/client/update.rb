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

    def self.clear(*arguments)
      Clear.new(*arguments)
    end

    class Operation
      attr_reader :options

      def initialize(*arguments)
        @options = arguments.last.is_a?(Hash) ? arguments.pop.dup : {}
        unless arguments.empty?
          send(arguments.shift, *arguments)
        end
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

      def to_s
        query_text = 'INSERT DATA {'
        query_text += ' GRAPH ' + SPARQL::Client.serialize_uri(self.options[:graph]) + ' {' if self.options[:graph]
        query_text += "\n"
        query_text += RDF::NTriples::Writer.buffer { |writer| writer << @data }
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
        query_text += RDF::NTriples::Writer.buffer { |writer| writer << @data }
        query_text += '}' if self.options[:graph]
        query_text += "}\n"
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#deleteInsert
    class DeleteInsert < Operation
      def to_s
        # TODO
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#load
    class Load < Operation
      def to_s
        # TODO
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#clear
    class Clear < Operation
      def silent
        self.options[:silent] = true
        self
      end

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
      def to_s
        # TODO
      end
    end

    ##
    # @see http://www.w3.org/TR/sparql11-update/#drop
    class Drop < Operation
      def to_s
        # TODO
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
