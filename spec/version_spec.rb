require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'SPARQL::Client::VERSION' do
  it "matches the VERSION file" do
    SPARQL::Client::VERSION.to_s.should == File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
