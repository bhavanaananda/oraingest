require 'vocabulary/bibo'
require 'vocabulary/fabio'
require 'vocabulary/ora'
require 'conference'

class ConferenceActivity
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :documentationStatus, :reviewStatus, :dateAccepted, :hadActivity

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceActivity")
    end
    }
  rdf_type rdf_type RDF::PROV.Activity
  map_predicates do |map|
    map.type(:in => RDF::DC)
    map.documentationStatus(:to => "DocumentStatus", :in => RDF::BIBO)
    map.reviewStatus(:in => RDF::ORA)
    map.dateAccepted(:in => RDF::DC)
    map.hadActivity(:in => RDF::PROV)
  end
  accepts_nested_attributes_for :hadActivity

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end 

  def to_solr(solr_doc={})
    if !self.dateAccepted.nil? && !self.dateAccepted.first.nil?
      begin
        solr_doc[Solrizer.solr_name("desc_metadata__dateAccepted", :dateable, type: :date)] = Time.parse(self.dateAccepted.first).utc.iso8601
      rescue ArgumentError
        # Not a valid date.  Don't put it into the solr doc, or solr will choke.
      end
    end
    solr_doc[Solrizer.solr_name("desc_metadata__documentationStatus", :stored_searchable)] = self.documentationStatus.first
    solr_doc[Solrizer.solr_name("desc_metadata__dateAccepted", :stored_searchable)] = self.dateAccepted.first
    # Index conference activity information
    if !self.hadActivity.nil? && !self.hadActivity.first.nil?
      self.hadActivity.first.to_solr(solr_doc)
    end
    solr_doc
  end
end
