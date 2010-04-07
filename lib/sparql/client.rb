require 'json'
require 'rdf'
require 'sparql/version'

module SPARQL
  ##
  class Client
    ##
    # @param  [String, #to_s]          url
    # @param  [Hash{Symbol => Object}] options
    def initialize(url, options = {}, &block)
      @url, @options = url, options

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end
  end
end
