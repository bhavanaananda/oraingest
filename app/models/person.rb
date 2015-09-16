require 'datastreams/person_rdf_datastream'
require 'rdf'

class Person < ActiveFedora::Base
  #include Sufia::GenericFile
  has_metadata name: 'descMetadata', type: PersonRdfDatastream
  
  has_attributes(
    :first_name, :last_name, :display_name, :name, :title, :email, :website, 
    :institution, :faculty, :oxford_college, :research_group, :webauth, :identifier,
    datastream: :descMetadata, 
    multiple: true
  )
  
end
