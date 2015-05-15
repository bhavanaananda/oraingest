require 'vocabulary/bibo'
require 'vocabulary/fabio'
require 'vocabulary/ora'

class ConferenceActivity
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :documentationStatus, :reviewStatus, :dateAccepted, :hadActivity

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceItemActivity")
    end
    }
  rdf_type rdf_type RDF::PROV.Activity
  map_predicates do |map|
    map.type(:in => RDF::DC)
    map.documentationStatus(:to => "DocumentStatus", :in => RDF::BIBO)
    map.reviewStatus(:in => RDF::ORA)
    map.dateAccepted(:in => RDF::DC)
    map.hadActivity(:in => RDF::PROV, class_name:"Conference")
  end
  accepts_nested_attributes_for :hasActivity

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
    if !self.hasActivity.nil? && !self.hasActivity.first.nil?
      self.hasActivity.first.to_solr(solr_doc)
    end
    solr_doc
  end
end
#
# class Conference
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::ConversionDAMS
#   attr_accessor  :generatedAtTime, :season, :startedAtTime, :endedAtTime, :atLocation, :wasAssociatedWith, :conferenceAssociation, :conferenceName, :conferenceAbbreviation, :conferenceHomepage, :conferenceProceeding
# conference_item_rdf_datastream
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conference")
#     end
#     }
#   rdf_type rdf_type RDF::BIBO.Conference
#   map_predicates do |map|
#     map.type(:in => RDF::DC)
#     map.generatedAtTime( :in => RDF::PROV)
#     map.season( :in => RDF::DBPEDIA)
#     map.startedAtTime( :in => RDF::PROV )
#     map.endedAtTime( :in => RDF::PROV )
#     map.atLocation( :in => RDF::PROV )
#     map.wasAssociatedWith( :in => RDF::PROV, class_name:"ConferenceOrganization")
#     map.conferenceAssociation(:to => "qualifiedAssociation", :in => RDF::PROV, class_name:"ConferenceAssociation")
#     map.conferenceName(:to => "n", :in => RDF::VCARD)
#     map.conferenceAbbreviation(:to => "nickname", :in => RDF::VCARD)
#     map.conferenceHomepage(:to => "homepage", :in => RDF::FOAF)
#     map.conferenceProceeding(:to => "generated", :in => RDF::PROV, class_name:"ConferenceProceeding")
#   end
#
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
#   def to_solr(solr_doc={})
#     solr_doc[Solrizer.solr_name("desc_metadata__generatedAtTime", :stored_searchable)] = self.title.first
#     solr_doc[Solrizer.solr_name("desc_metadata__season", :symbol)] = self.issn.first
#     solr_doc[Solrizer.solr_name("desc_metadata__startedAtTime", :symbol)] = self.eissn.first
#     solr_doc[Solrizer.solr_name("desc_metadata__endedAtTime", :displayable)] = self.volume.first
#     solr_doc[Solrizer.solr_name("desc_metadata__atLocation", :displayable)] = self.issue.first
#     solr_doc[Solrizer.solr_name("desc_metadata__wasAssociatedWith", :displayable)] = self.pages.first
#     solr_doc[Solrizer.solr_name("desc_metadata__conferenceAssociation", :displayable)] = self.pages.first
#     solr_doc[Solrizer.solr_name("desc_metadata__conferenceName", :displayable)] = self.pages.first
#     solr_doc[Solrizer.solr_name("desc_metadata__conferenceAbbreviation", :displayable)] = self.pages.first
#     solr_doc[Solrizer.solr_name("desc_metadata__conferenceHomepage", :displayable)] = self.pages.first
#     solr_doc[Solrizer.solr_name("desc_metadata__conferenceProceeding", :displayable)] = self.pages.first
#
#     solr_doc
#   end
# end
#
# class ConferenceOrganization
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   #attr_accessor :title
#
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceOrganization")
#     end
#     }
#   rdf_type rdf_type RDF::FOAF.Organization
#   map_predicates do |map|
#     map.title(:in => RDF::VCARD)
#   end
#
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end
#
# class ConferenceAssociation
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :agent, :isOrganizedBy
#
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceAssociation")
#     end
#     }
#   rdf_type rdf_type RDF::PROV.Association
#   map_predicates do |map|
#     map.agent(:in => RDF::PROV, class_name:"ConferenceOrganization")
#     map.isOrganizedBy(:to => "hadRole",:in => RDF::PROV, class_name:"ConferenceOrganizer")
#   end
#
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end
#
# class ConferenceOrganizer
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :name
#
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceOrganizer")
#     end
#     }
#   rdf_type rdf_type RDF::BIBO.Organizer
#   map_predicates do |map|
#     map.name(:to => n, :in => RDF::VCARD)
#   end
#
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end
#
# class ConferenceProceeding
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :title, :issn, :eissn, :isbn, :volume, :pages, :wasAttributedTo, :qualifiedAtribution
#
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceProceeding")
#     end
#     }
#   rdf_type rdf_type RDF::BIBO.Proceedings
#   rdf_type rdf_type RDF::PROV.Entity
#   map_predicates do |map|
#     map.title(:in => RDF::DC)
#     map.issn(:in => RDF::BIBO)
#     map.eissn(:in => RDF::BIBO)
#     map.isbn(:in => RDF::BIBO)
#     map.volume(:in => RDF::BIBO)
#     map.pages(:in => RDF::BIBO)
#     map.wasAttributedTo(:in => RDF::PROV, class_name:"ConferenceProceedingAttributor")
#     map.qualifiedAttribution(:in => RDF::PROV, class_name:"ConferenceProceedingAttribution")
#   end
#
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end
#
# class ConferenceProceedingAttributor
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :name, :sameAs
#
#   rdf_subject { |ds|ConferenceAttribution
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceProceedingAttributor")
#     end
#     }
#   rdf_type rdf_type RDF::FOAF:Person
#   map_predicates do |map|
#     map.name(:to => "n",:in => RDF::VCARD)
#     map.sameAs(:in => RDF::OWL)
#   end
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end
#
# class ConferenceAttribution
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor :conferenceProceedingAttributor, :sameAs
#
#   rdf_subject { |ds|
#     if ds.pid.nil?
#       RDF::URI.new
#     else
#       RDF::URI.new("info:fedora/" + ds.pid + "#conferenceAttribution")
#     end
#     }
#   rdf_type rdf_type RDF::PROV.Attribution
#   map_predicates do |map|
#     map.conferenceProceedingAttributor(:to => "agent",:in => RDF::PROV, class_name:"ConferenceProceedingAttributor")
#     map.sameAs(:in => RDF::OWL)
#   end
#   def persisted?
#     rdf_subject.kind_of? RDF::URI
#   end
#
#   def id
#     rdf_subject if rdf_subject.kind_of? RDF::URI
#   end
#
# end