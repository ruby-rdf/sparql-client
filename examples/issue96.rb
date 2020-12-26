require 'sparql/client'
SPARQL::Client::Query
  .select
  .where(%i[s p o])
  .values(:s, RDF::URI('http://example.com/1'), RDF::URI('http://example.com/2'))
