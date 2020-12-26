require 'rdf'
require 'sparql/client'
dnbt = RDF::Vocabulary.new("https://d-nb.info/standards/elementset/dnb#")
rdf_gndid = RDF::Literal.new("https://d-nb.info/gnd/1059461498")
sparql_client = SPARQL::Client.new("http://127.0.0.1:9292/")
gndo = RDF::Vocabulary.new("http://d-nb.info/gnd/standards/elementset/gnd#")
query = sparql_client.select.where([:subject, dnbt.deprecatedUri, rdf_gndid]).where([:subject, gndo.gndIdentifier, :gndid])
query.each_solution { |solution| new_gndid = solution[:gndid].to_s }