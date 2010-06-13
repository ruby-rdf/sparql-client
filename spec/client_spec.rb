require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client do
  describe "when querying" do
    before(:each) do
      @client = SPARQL::Client.new('http://data.linkedmdb.org/sparql')
      @query = 'DESCRIBE ?kb WHERE  { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'
    end

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header
      response.stub!(:body).and_return('body')
      response
    end

    it "should handle successful response with plain header" do
      @client.should_receive(:get).and_yield response('text/plain')
      RDF::Reader.should_receive(:for).with(:content_type=>'text/plain')
      @client.query(@query)
    end

    it "should handle successful response with boolean header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_BOOL)
      @client.query(@query).should == false
    end

    it "should handle successful response with json header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_JSON)
      @client.should_receive(:parse_json_bindings)
      @client.query(@query)
    end

    it "should handle successful response with xml header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_XML)
      @client.should_receive(:parse_xml_bindings)
      @client.query(@query)
    end
  end
end