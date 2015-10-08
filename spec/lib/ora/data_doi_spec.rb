require 'rails_helper'
require File.expand_path('lib/ora/data_doi', Rails.root)
describe ORA::DataDoi do
  
  let(:username)     { 'Bob'}
  let(:password)     { 'something.long' }
  let(:shoulder)     { 'shoulder'}
  let(:url)          { 'http://example.com'}
  let(:resolver_url) {'http://example.com/resolver'}
  
  let(:payload) do 
    {
       identifier: '10.foo/bar', 
       creator: ['Harry Hatstand'], 
       title: 'Something', 
       publisher: 'Somebody', 
       publicationYear: '2015'
    }
  end
  
  let(:data_doi) do 
    ORA::DataDoi.new(
          username: username,
          password: password,
          shoulder: shoulder,
               url: url,
      resolver_url: resolver_url
    )
  end
  
  describe '#normalize_identifier' do
    it 'should desc add doi to value' do
      expect(data_doi.normalize_identifier('foo')).to eq('foo')
    end
    
    it 'should add doi: to start if first character a number' do
      expect(data_doi.normalize_identifier('4oo')).to eq('doi:4oo')
    end
    
    it 'should remove spaces around leading doi:' do
      expect(data_doi.normalize_identifier(' doi: foo')).to eq('doi:foo')
    end
    
    it 'should remove leading resolver url' do
      identifier = "#{resolver_url}foo"
      expect(data_doi.normalize_identifier(identifier)).to eq('foo')
    end
  end
  
  describe '#remote_uri_for' do
    it 'should append identifier to url and convert to URI' do
      identifier = 'foo'
      expected = URI.parse(File.join(resolver_url, identifier))
      expect(data_doi.remote_uri_for(identifier)).to eq(expected)
    end
  end
  
  describe '#valid_attribute?' do
    it 'should return true if attribute in REQUIRED_ATTRIBUTES' do
      attr = ORA::DataDoi::REQUIRED_ATTRIBUTES.first
      expect(data_doi.valid_attribute?(attr)).to eq(true)
    end
    
    it 'should return false if attribute unknown' do
      expect(data_doi.valid_attribute?('unknown')).to eq(false)
    end
  end
  
  describe '#call' do
    
    let(:failure_message) { 'Oh dear!' }
    let(:failure_code)    { 400 }
    
    context 'with successful responses' do
    
      before do
        stub_request(:post, "http://#{username}:#{password}@example.com/metadata").
          to_return(:status => 200, :body => "", :headers => {})
        stub_request(:post, "http://#{username}:#{password}@example.com/doi").
          to_return(:status => 200, :body => "", :headers => {})
        data_doi.call({creator: ['Joe Bloggs']})
      end
    
      it 'should set a message' do
        expect(data_doi.msg).to eq(["Doi with metadata registered"]
        )
      end
      
      it 'should set status to true' do
        expect(data_doi.status).to eq(true)
      end
    
    end
    
    context 'with failed metadata request' do
      
      before do
        stub_request(:post, "http://#{username}:#{password}@example.com/metadata").
          to_return(:status => failure_code, :body => failure_message, :headers => {})
        data_doi.call({creator: ['Joe Bloggs']})
      end
      
      it 'should set a message containing the failure code and message' do
        expect(data_doi.msg.first).to match(failure_message)
        expect(data_doi.msg.first).to match(failure_code.to_s)
      end
      
      it 'should set status to false' do
        expect(data_doi.status).to eq(false)
      end
      
    end
    
    context 'with failed doi request' do
      
      before do
        stub_request(:post, "http://#{username}:#{password}@example.com/metadata").
          to_return(:status => 200, :body => "", :headers => {})
        stub_request(:post, "http://#{username}:#{password}@example.com/doi").
          to_return(:status => failure_code, :body => failure_message, :headers => {})
        data_doi.call({creator: ['Joe Bloggs']})
      end
      
    end
    
  end
  
  describe '#validate_required' do
    
    let(:payload) do 
      {
         identifier: 'something', 
         creator: 'something', 
         title: 'something', 
         publisher: 'something', 
         publicationYear: 'something'
      }
    end
    
    context 'with valid payload' do     
      it 'should complete without raising an error' do
        expect(data_doi.validate_required(payload)).to eq(nil)
      end      
    end
    
    context 'with required attribute missing' do
      it 'should raise exception' do
        payload.delete :title
        expect {
          data_doi.validate_required(payload)
        }.to raise_error(ORA::DataValidationError)
      end
    end
    
    context 'with required attribute blank' do
      it 'should raise exception' do
        payload[:title] = " "
        expect {
          data_doi.validate_required(payload)
        }.to raise_error(ORA::DataValidationError)
      end
    end
    
  end
  
  describe '#validate_xml' do
        
    context 'with valid payload' do
      it 'should complete without raising an error' do
        expect(data_doi.validate_xml(payload)).to eq(nil)
      end
    end
    
    context 'with invalid payload' do
      it 'should raise exception' do
        payload[:identifier] = '10.foo'
        expect {
          data_doi.validate_xml(payload)
        }.to raise_error(ORA::DataValidationError)
      end
    end
    
  end
  
  describe '#to_xml' do
    
    # As #validate_xml calls to_xml, testing validate_xml tests both
    # methods. So no need for additional tests.
    
  end
end

