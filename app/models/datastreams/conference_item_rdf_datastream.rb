require 'rdf'
require 'vocabulary/bibo'
require 'vocabulary/ora'
require 'fields/conference_activity'
require 'fields/publication_activity'
require 'conference'

class ConferenceItemRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  attr_accessor  :presentedAt, :hadConferenceActivity, :hadPublicationActivity
  rdf_type rdf_type RDF::PROV.Entity

  map_predicates do |map|
    map.type(:in => RDF::DC)
    map.presentedAt( :in => RDF::BIBO,  class_name:"Conference")
    map.hadConferenceActivity( :in => RDF::ORA,  class_name:"ConferenceActivity")
    map.hadPublicationActivity( :in => RDF::ORA,  class_name:"PublicationActivity")
  end
  accepts_nested_attributes_for :presentedAt
  accepts_nested_attributes_for :hadConferenceActivity
  accepts_nested_attributes_for :hadPublicationActivity

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})

    # Index each conference individually:

    self.presentedAt.each do |conf|
      already_indexed = []
      unless conf.name.empty? || already_indexed.include?(conf.name.first)
        conf.to_solr(solr_doc)
        already_indexed << conf.name.first
      end
    end

    # Index each conferenceActivity individually
    self.hadConferenceActivity.each do |c|
      c.to_solr(solr_doc)
    end

    # Index each publicationActivity individually
    self.hadPublicationActivity.each do |c|
      c.to_solr(solr_doc)
    end
    solr_doc
  end

end
