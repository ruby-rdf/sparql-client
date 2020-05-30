require_relative 'spec_helper'

describe 'SPARQL::Client::VERSION' do
  it "matches the VERSION file" do
    expect(SPARQL::Client::VERSION.to_s).to eq File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
