module SPARQL

  # <http://www.w3.org/TR/rdf-sparql-query/#QueryForms>
  class Query

    def self.parse(sparql)
      raise NotImplementedError
    end

    # <http://www.w3.org/TR/rdf-sparql-query/#select>
    def self.select(args = {}) end

    # <http://www.w3.org/TR/rdf-sparql-query/#construct>
    def self.construct(args = {}) end

    # <http://www.w3.org/TR/rdf-sparql-query/#ask>
    def self.ask(args = {}) end

    # <http://www.w3.org/TR/rdf-sparql-query/#describe>
    def self.describe(args = {}) end

    def to_s() end

    protected

      def initialize(type, args = {}) end

  end
end
