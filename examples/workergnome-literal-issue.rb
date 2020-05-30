#require 'rdf/turtle'
require 'sparql/client'

sparql = SPARQL::Client.new("http://data.americanartcollaborative.org/sparql")
uri = RDF.URI("http://data.crystalbridges.org/object/2258")
label = RDF::RDFS.label

query = sparql.construct([uri, label, :o]).where([uri, label, :o])
query.each_statement do |s|
  puts s.object.inspect
end

# <http://data.crystalbridges.org/object/2258> <http://www.w3.org/2000/01/rdf-schema#label> "Bison-Dance of the Mandan Indians in front of their Medicine Lodge in Mih-Tuta-Hankush" .
# <http://data.crystalbridges.org/object/2258> <http://www.w3.org/2000/01/rdf-schema#label> "From \"Voyage dans l’intérieur de l’Amérique du Nord, executé pendant les années 1832, 1833 et 1834, par le prince Maximilien de Wied-Neuwied\" (Paris & Coblenz, 1839-1843)" .

# "<http://data.crystalbridges.org/object/2258> <http://www.w3.org/2000/01/rdf-schema#label> \"Bison-Dance of the Mandan Indians in front of their Medicine Lodge in Mih-Tuta-Hankush\" .\n<http://data.crystalbridges.org/object/2258> <http://www.w3.org/2000/01/rdf-schema#label> \"From \\\"Voyage dans l\xE2\x80\x99int\xC3\xA9rieur de l\xE2\x80\x99Am\xC3\xA9rique du Nord, execut\xC3\xA9 pendant les ann\xC3\xA9es 1832, 1833 et 1834, par le prince Maximilien de Wied-Neuwied\\\" (Paris & Coblenz, 1839-1843)\" .\n"