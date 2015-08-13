#require 'active_support/concern'
require 'rdf'
#require 'datastreams/person_rdf_datastream'
#Vocabularies
require 'vocabulary/bibo'
require 'vocabulary/camelot'
require 'vocabulary/ora'
require 'vocabulary/dams'
require 'vocabulary/frapo'
require 'vocabulary/time'
require 'vocabulary/event'
require 'vocabulary/dbpedia'

# Fields
require 'fields/mads_language'
require 'fields/mads_subject'
require 'fields/work_type'
require 'fields/rights_activity'
require 'fields/funding_activity'
require 'fields/creation_activity'
require 'fields/publication_activity'
require 'fields/location'

class ConferenceItemRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  #include ModelHelper

  attr_accessor :title, :subtitle, :abstract, :subject, :keyword, :worktype, :medium, :language, :publicationStatus, :reviewStatus, :license, :dateCopyrighted, :rightsHolder, :rights, :rightsActivity, :creation, :funding, :publication, :presentedAt
  rdf_type rdf_type RDF::PROV.Entity
  map_predicates do |map|
    #-- title --
    map.title(:in => RDF::DC)
    #-- subtitle --
    map.subtitle(:in => RDF::DAMS)
    #-- abstract --
    map.abstract(:in => RDF::DC)
    #-- subject --
    map.subject(:in => RDF::DC, class_name:"MadsSubject")
    #-- keyword --
    map.keyword(:in => RDF::CAMELOT)
    #-- type --
    map.worktype(:to=>"type", :in => RDF::DC, class_name:"WorkType")
    #-- medium --conferenceNameconferenceName
    map.medium(:in => RDF::DC)
    #-- language --
    map.language(:in => RDF::DC, class_name:"MadsLanguage")
    # -- publication status --
    #TODO: Check if this is used. May be replaced by one in publication activity
    map.publicationStatus(:to => "DocumentStatus", :in => RDF::BIBO)
    # -- review status --
    #TODO: Check if this is used. May be replaced by one in publication activity
    map.reviewStatus(:in => RDF::ORA)
    # -- rights activity --
    map.license(:in => RDF::DC, class_name:"LicenseStatement")
    map.dateCopyrighted(:in => RDF::DC)
    map.rightsHolder(:in => RDF::DC)
    map.rights(:in => RDF::DC, class_name:"RightsStatement")
    map.rightsActivity(:in => RDF::PROV, :to => "hadActivity", class_name:"RightsActivity")
    # -- creation activity --
    # TODO: link with Fedora person objects
    map.creation(:to => "hadCreationActivity", :in => RDF::ORA, class_name:"CreationActivity")
    # -- funding activity --
    # TODO: Lookup and link with Fedora funder objects
    map.funding(:to => "isOutputOf", :in => RDF::FRAPO, class_name:"FundingActivity")
    #-- publication activity --
    map.publication(:to => "hadPublicationActivity", :in => RDF::ORA, class_name:"PublicationActivity")
    #-- conference  --
    map.presentedAt(:in => RDF::BIBO, class_name:"Conference")
  end
  accepts_nested_attributes_for :language
  accepts_nested_attributes_for :subject
  accepts_nested_attributes_for :worktype
  accepts_nested_attributes_for :license
  accepts_nested_attributes_for :rights
  accepts_nested_attributes_for :rightsActivity
  accepts_nested_attributes_for :creation
  accepts_nested_attributes_for :funding
  accepts_nested_attributes_for :publication
  accepts_nested_attributes_for :presentedAt


  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__title", :stored_searchable)] = self.title
    solr_doc[Solrizer.solr_name("desc_metadata__subtitle", :stored_searchable)] = self.subtitle
    solr_doc[Solrizer.solr_name("desc_metadata__abstract", :stored_searchable)] = self.abstract
    solr_doc[Solrizer.solr_name("desc_metadata__keyword", :stored_searchable)] = self.keyword
    solr_doc[Solrizer.solr_name("desc_metadata__medium", :stored_searchable)] = self.medium
    solr_doc[Solrizer.solr_name("desc_metadata__publicationStatus", :stored_searchable)] = self.publicationStatus
    solr_doc[Solrizer.solr_name("desc_metadata__reviewStatus", :stored_searchable)] = self.reviewStatus
    #solr_doc[Solrizer.solr_name("dateCopyrighted", :stored_searchable, type: :date)] = self.dateCopyrighted
    # Need to validate data and convert it to proper date format before indexing as date
    solr_doc[Solrizer.solr_name("desc_metadata__dateCopyrighted", :stored_searchable)] = self.dateCopyrighted
    solr_doc[Solrizer.solr_name("desc_metadata__rightsHolder", :stored_searchable)] = self.rightsHolder
    # Index the type of work
    self.worktype.each do |w|
      already_indexed = []
      unless w.typeLabel.empty? || already_indexed.include?(w.typeLabel.first)
        w.to_solr(solr_doc)
        already_indexed << w.typeLabel.first
      end
    end
    # Index each language individually
    self.language.each do |l|
      already_indexed = []
      unless l.languageLabel.empty? || already_indexed.include?(l.languageLabel.first)
        l.to_solr(solr_doc)
        already_indexed << l.languageLabel.first
      end
    end
    # Index each subject individually
    self.subject.each do |s|
      already_indexed = []
      unless s.subjectLabel.empty? || already_indexed.include?(s.subjectLabel.first)
        s.to_solr(solr_doc)
        already_indexed << s.subjectLabel.first
      end
    end
    # Index each creator individually
    self.creation.each do |c|
      c.to_solr(solr_doc)
    end
    # Index each license individually
    self.license.each do |l|
      l.to_solr(solr_doc)
    end
    # Index each publication individually
    self.publication.each do |p|
      p.to_solr(solr_doc)
    end
    # Index each funding individually
    self.funding.each do |f|
      f.to_solr(solr_doc)
    end

    # Index each conference individually
    self.presentedAt.each do |f|
      f.to_solr(solr_doc)
    end


    solr_doc
  end

end


class Conference
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :conferenceName, :conferenceAbbreviation, :conferenceHomepage, :conferenceStartDate,:conferenceEndDate, :season, :spatial , :wasAssociatedWith, :conferenceAssociation

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
    map.conferenceStartDate(:to => "conferenceStartDate", :in => RDF::ORA)
    map.conferenceEndDate(:to => "conferenceEndDate", :in => RDF::ORA)
    map.season(:in => RDF::DBPEDIA)
    map.spatial(:in => RDF::DC, class_name:"Location")
    map.wasAssociatedWith( :in => RDF::PROV, class_name:"ConferenceOrganization")
    map.conferenceAssociation(:to => "qualifiedAssociation", :in => RDF::PROV, class_name:"ConferenceAssociation")
  end
  accepts_nested_attributes_for :wasAssociatedWith
  accepts_nested_attributes_for :conferenceAssociation
  accepts_nested_attributes_for :creation
  accepts_nested_attributes_for :spatial


  def persisted?
    rdf_subject.kind_of? RDF::URI
  end


  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__season", :symbol)] = self.season.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceStartDate", :displayable)] = self.conferenceStartDate.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceEndDate", :displayable)] = self.conferenceEndDate.first
    if !self.spatial.nil? && !self.spatial.first.nil?
      solr_doc[Solrizer.solr_name("desc_metadata__spatial", :stored_searchable)] = self.spatial.first.value
    end
    #solr_doc[Solrizer.solr_name("desc_metadata__wasAssociatedWith", :displayable)] = self.wasAssociatedWith.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAssociation", :displayable)] = self.conferenceAssociation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceName", :displayable)] = self.conferenceName.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAbbreviation", :displayable)] = self.conferenceAbbreviation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceHomepage", :displayable)] = self.conferenceHomepage.first
    # Index each conferenceOrganization individually:



    self.wasAssociatedWith.each do |corg|
      already_indexed = []
      unless corg.name.empty? || already_indexed      #WorkflowPublisher.new(@conference).perform_action(current_user)
        corg.to_solr(solr_doc)
        already_indexed << corg.name.first
      end
    end

    # Index each conferenceAssociation individually
    self.conferenceAssociation.each do |c|
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