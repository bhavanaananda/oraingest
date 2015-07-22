#require 'active_support/concern'
require 'rdf'
#require 'datastreams/person_rdf_datastream'
#Vocabularies
require 'vocabulary/bibo'
require 'vocabulary/ora'
require 'vocabulary/time'
require 'vocabulary/event'
require 'vocabulary/dbpedia'
#require 'vocabulary/foaf'
# Fields
require 'fields/creation_activity'
require 'fields/location'

#require 'fields/conference_activity'


class ConferenceRdfDatastream < ActiveFedora::NtriplesRDFDatastream
 # include ActiveFedora::RdfObject
 # extend ActiveModel::Naming
 # include ActiveModel::Conversion
  attr_accessor  :conferenceDate, :season, :location , :wasAssociatedWith, :conferenceAssociation, :conferenceName, :conferenceAbbreviation, :conferenceHomepage, :conferenceOrganization, :conferenceOrganizer, :conferenceProceeding, :conferenceProceedingAttributor, :conferenceProceedingAttribution, :creation

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conference")
    end
    }

  rdf_type rdf_type RDF::BIBO.Conference

  map_predicates do |map|
    map.type(:in => RDF::DC)
    map.conferenceName(:to => "n", :in => RDF::VCARD)
    map.conferenceAbbreviation(:to => "nickname", :in => RDF::VCARD)
    map.conferenceHomepage(:to => "homepage", :in => RDF::FOAF)
    map.conferenceDate(:to => "hasConferenceDuration", :in => RDF::ORA, class_name: "ConferenceDate")
    map.season(:in => RDF::DBPEDIA)
    map.spatial(:in => RDF::DC, class_name:"Location")
    map.wasAssociatedWith( :in => RDF::PROV, class_name:"ConferenceOrganization")
    map.conferenceAssociation(:to => "qualifiedAssociation", :in => RDF::PROV, class_name:"ConferenceAssociation")
    map.conferenceProceeding(:to => "generated", :in => RDF::PROV, class_name:"ConferenceProceeding")
    map.creation(:to => "hadCreationActivity", :in => RDF::ORA, class_name:"CreationActivity")
  end
  accepts_nested_attributes_for :wasAssociatedWith
  accepts_nested_attributes_for :conferenceAssociation
  accepts_nested_attributes_for :conferenceProceeding
  accepts_nested_attributes_for :creation
  accepts_nested_attributes_for :spatial


  def persisted?
    rdf_subject.kind_of? RDF::URI
  end


  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__season", :symbol)] = self.season.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceDate", :displayable)] = self.conferenceDate.first
    if !self.spatial.nil? && !self.spatial.first.nil?
      solr_doc[Solrizer.solr_name("desc_metadata__spatial", :stored_searchable)] = self.spatial.first.value
    end

    solr_doc[Solrizer.solr_name("desc_metadata__wasAssociatedWith", :displayable)] = self.wasAssociatedWith.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAssociation", :displayable)] = self.conferenceAssociation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceName", :displayable)] = self.conferenceName.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAbbreviation", :displayable)] = self.conferenceAbbreviation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceHomepage", :displayable)] = self.conferenceHomepage.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceProceeding", :displayable)] = self.conferenceProceeding.first
    solr_doc[Solrizer.solr_name("desc_metadata__creation", :displayable)] = self.creation.first

    # Index each conferenceOrganization individually:

        self.wasAssociatedWith.each do |corg|
          already_indexed = []
          unless corg.name.empty? || already_indexed.include?(corg.name.first)
            corg.to_solr(solr_doc)
            already_indexed << corg.name.first
          end
        end

        # Index each conferenceAssociation individually
        self.conferenceAssociation.each do |c|
            c.to_solr(solr_doc)
        end



        # Index each conferenceProceeding individually
        self.conferenceProceeding.each do |c|
          c.to_solr(solr_doc)
        end

    solr_doc
  end

end


class ConferenceOrganization
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor  :name

  rdf_subject { |ds|
    if ds.pid.nil?

      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceOrganization")
    end
    }
  rdf_type rdf_type RDF::FOAF.Organization
  map_predicates do |map|
    map.name(:to => "n", :in => RDF::VCARD)
  end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__name", :stored_searchable)] = self.name.first
    solr_doc
  end
end

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
#   }
#   rdf_type rdf_type RDF::BIBO.Organizer
#   map_predicates do |map|
#     map.name(:to => "n", :in => RDF::VCARD)
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
#
#   def to_solr(
#
# endsolr_doc={})
#     solr_doc[Solrizer.solr_name("desc_metadata__name", :stored_searchable)] = self.name.first
#     solr_doc
#   end
#
# end


class ConferenceDate
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :start, :end, :duration

  rdf_type RDF::TIME.TemporalEntity
  map_predicates do |map|
    #-- conferenceStart --
    map.start(:to => "hasBeginning", :in => RDF::TIME, class_name: "LabelledDate")
    #-- conferenceDuration --
    map.duration(:to => "hasDurationDescription", :in => RDF::TIME, class_name: "ConferenceDuration")
    #-- conferenceEnd --
    map.end(:to => "hasEnd", :in => RDF::TIME, class_name: "LabelledDate")
  end
  accepts_nested_attributes_for :start
  accepts_nested_attributes_for :duration
  accepts_nested_attributes_for :end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end
end


class ConferenceAssociation
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :conferenceOrganization, :isOrganizedBy

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceAssociation")
    end
    }
  rdf_type rdf_type RDF::PROV.Association
  map_predicates do |map|
    map.conferenceOrganization(:to => "agent", :in => RDF::PROV, class_name:"ConferenceOrganization")
    map.isOrganizedBy(:to => "hadRole",:in => RDF::PROV, class_name:RDF::BIBO.Organizer)
  end

  accepts_nested_attributes_for :conferenceOrganization
  #accepts_nested_attributes_for :isOrganizedBy

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    # Index each ConferenceOrganization individually
    self.conferenceOrganization.each do |c|
      c.to_solr(solr_doc)
    end
    solr_doc
  end

end


class ConferenceProceeding
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :title, :issn, :eissn, :isbn, :volume, :pages, :conferenceProceedingAttributor, :conferenceProceedingAttribution

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceProceeding")# class Conference
    end
  }
  rdf_type rdf_type RDF::BIBO.Proceedings
  #rdf_type rdf_type RDF::PROV.Entity
  map_predicates do |map|
    map.title(:in => RDF::DC)
    map.issn(:in => RDF::BIBO)
    map.eissn(:in => RDF::BIBO)
    map.isbn(:in => RDF::BIBO)
    map.volume(:in => RDF::BIBO)
    map.pages(:in => RDF::BIBO)
    map.conferenceProceedingAttributor(:to =>  "wasAttributedTo", :in => RDF::PROV, class_name:"ConferenceProceedingAttributor")
    map.conferenceProceedingAttribution(:to => "qualifiedAttribution", :in => RDF::PROV, class_name:"ConferenceProceedingAttribution")
  end


  accepts_nested_attributes_for :ConferenceProceedingAttributor
  accepts_nested_attributes_for :ConferenceProceedingAttribution

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__title", :stored_searchable)] = self.title.first
    solr_doc[Solrizer.solr_name("desc_metadata__issn", :symbol)] = self.issn.first
    solr_doc[Solrizer.solr_name("desc_metadata__eissn", :symbol)] = self.eissn.first
    solr_doc[Solrizer.solr_name("desc_metadata__isbn", :symbol)] = self.isbn.first
    solr_doc[Solrizer.solr_name("desc_metadata__volume", :displayable)] = self.volume.first
    solr_doc[Solrizer.solr_name("desc_metadata__pages", :displayable)] = self.pages.first

    # Index each ConferenceProceedingAttributor individually
    self.conferenceProceedingAttributor.each do |c|
      c.to_solr(solr_doc)
    end

    # Index each ConferenceProceedingAttribution individually
    self.conferenceProceedingAttribution.each do |c|
      c.to_solr(solr_doc)
    end
    solr_doc
  end
end


class ConferenceProceedingAttributor
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :name, :sameAs

  rdf_subject { |ds|
  if ds.pid.nil?
    RDF::URI.new
  else
    RDF::URI.new("info:fedora/" + ds.pid + "#conferenceProceedingAttributor")
  end
  }

  rdf_type rdf_type RDF::FOAF.Person
  map_predicates do |map|
    map.name(:to => "n",:in => RDF::VCARD)
    map.sameAs(:in => RDF::OWL)
  end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__name", :stored_searchable)] = self.name.first
    solr_doc
  end

end


class ConferenceProceedingAttribution

  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :conferenceProceedingAttributor, :hadRole

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceAttribution")
    end
    }
  rdf_type rdf_type RDF::PROV.Attribution
  map_predicates do |map|
    map.conferenceProceedingAttributor(:to => "agent",:in => RDF::PROV, class_name:"ConferenceProceedingAttributor")
    map.hadRole(:in => RDF::PROV )
  end

  accepts_nested_attributes_for :ConferenceProceedingAttributor

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    # Index each ConferenceProceedingAttributor individually
    self.conferenceProceedingAttributor.each do |c|
      c.to_solr(solr_doc)
    end

    solr_doc
  end

end



class LabelledDate
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :date, :label

  map_predicates do |map|
    #-- start date --
    map.date(:to=> 'value', :in => RDF)
    #-- start description --
    map.label(:in => RDF::RDFS)
  end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

end


class ConferenceDuration
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :years, :months

  map_predicates do |map|
    #-- embargo duration - years --
    map.years(:in => RDF::TIME)
    #-- embargo duration - months --
    map.months(:in => RDF::TIME)
  end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

end

class ConferenceDate
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :start, :end, :duration

  rdf_type RDF::TIME.TemporalEntity
  map_predicates do |map|
    #-- conferenceStart --
    map.start(:to => "hasBeginning", :in => RDF::TIME, class_name: "LabelledDate")
    #-- conferenceDuration --
    map.duration(:to => "hasDurationDescription", :in => RDF::TIME, class_name: "ConferenceDuration")
    #-- embargoEnd --
    map.end(:to => "hasEnd", :in => RDF::TIME, class_name: "LabelledDate")
  end
  accepts_nested_attributes_for :start
  accepts_nested_attributes_for :duration
  accepts_nested_attributes_for :end

  def persisted?
    rdf_subject.kind_of? RDF::URI
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

end
