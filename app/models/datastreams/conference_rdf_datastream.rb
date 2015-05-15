#require 'active_support/concern'
require 'rdf'
#require 'datastreams/person_rdf_datastream'
#Vocabularies
require 'vocabulary/bibo'
require 'vocabulary/ora'
require 'vocabulary/event'
require 'vocabulary/dbpedia'
#require 'vocabulary/foaf'
# Fields
require 'fields/creation_activity'
require 'fields/conference_activity'


class ConferenceRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor  :time, :season, :place , :wasAssociatedWith, :conferenceAssociation, :conferenceName, :conferenceAbbreviation, :conferenceHomepage, :conferenceProceeding, :hadCreationActivity

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
    map.time( :in => RDF::EVENT)
    map.season( :in => RDF::DBPEDIA)
    map.place( :in => RDF::EVENT)
    map.wasAssociatedWith( :in => RDF::PROV, class_name:"ConferenceOrganization")
    map.conferenceAssociation(:to => "qualifiedAssociation", :in => RDF::PROV, class_name:"ConferenceAssociation")
    map.conferenceName(:to => "n", :in => RDF::VCARD)
    map.conferenceAbbreviation(:to => "nickname", :in => RDF::VCARD)
    map.conferenceHomepage(:to => "homepage", :in => RDF::FOAF)
    map.conferenceProceeding(:to => "generated", :in => RDF::PROV, class_name:"ConferenceProceeding")
    map.hadCreationActivity(:in => RDF::ORA, class_name:"CreationActivity")
  end
  accepts_nested_attributes_for :wasAssociatedWith
  accepts_nested_attributes_for :conferenceAssociation
  accepts_nested_attributes_for :conferenceProceeding
  accepts_nested_attributes_for :hadCreationActivity

  def persisted?
    rdf_subject.kind_of? RDF::URI    solr_doc[Solrizer.solr_name("desc_metadata__season", :symbol)] = self.issn.first
    solr_doc[Solrizer.solr_name("desc_metadata__startedAtTime", :symbol)] = self.eissn.first
    solr_doc[Solrizer.solr_name("desc_metadata__endedAtTime", :displayable)] = self.volume.first
    solr_doc[Solrizer.solr_name("desc_metadata__atLocation", :displayable)] = self.issue.first
    solr_doc[Solrizer.solr_name("desc_metadata__wasAssociatedWith", :displayable)] = self.pages.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAssociation", :displayable)] = self.pages.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceName", :displayable)] = self.pages.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceAbbreviation", :displayable)] = self.pages.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceHomepage", :displayable)] = self.pages.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceProceeding", :displayable)] = self.pages.first
  end

  def id
    rdf_subject if rdf_subject.kind_of? RDF::URI
  end

  def to_solr(solr_doc={})
    solr_doc[Solrizer.solr_name("desc_metadata__time", :stored_searchable)] = self.time.first
    solr_doc[Solrizer.solr_name("desc_metadata__season", :symbol)] = self.season.first
    solr_doc[Solrizer.solr_name("desc_metadata__place", :symbol)] = self.place.first
    #solr_doc[Solrizer.solr_name("desc_metadata__was
    # AssociatedWith", :displayable)] = self.wasAssociatedWith.first
    # solr_doc[Solrizer.solr_name("desc_metadata__conferenceAssociation", :displayable)] = self.conferenceAssociation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceName", :displayable)] = self.conferenceName.first
    # solr_doc[Solrizer.solr_name("desc_metadata__conferenceAbbreviation", :displayable)] = self.co# class ConferenceOrganizer
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
# endnferenceAbbreviation.first
    solr_doc[Solrizer.solr_name("desc_metadata__conferenceHomepage", :displayable)] = self.pages.first
    #solr_doc[Solrizer.solr_name("desc_metadata__hadCreationActivity ", :displayable)] = self.hadCreationActivity.first

    # Index each conferenceOrganization individually
        self.wasAssociatedWith.each do |corg|
          already_indexed = []
          unless corg.title.empty? || already_indexed.include?(corg.title.first)
            corg.to_solr(solr_doc)
            already_indexed << corg.title.first
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

        # Index each creationActivity individually
        self.creationActivity.each do |c|
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
    map.isOrganizedBy(:to => "hadRole",:in => RDF::PROV, class_name:"ConferenceOrganizer")
  end

  accepts_nested_attributes_for :conferenceOrganization
  accepts_nested_attributes_for :isOrganizedBy

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
    # Index each ConferenceOrganizer individually
    self.isOrganizedBy.each do |c|
      c.to_solr(solr_doc)
    end
    solr_doc
  end

end


class ConferenceOrganizer
  include ActiveFedora::RdfObject
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :name

  rdf_subject { |ds|
    if ds.pid.nil?
      RDF::URI.new
    else
      RDF::URI.new("info:fedora/" + ds.pid + "#conferenceOrganizer")
    end
    }
  rdf_type rdf_type RDF::BIBO.Organizer
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
#   include ActiveFedora::RdfObject
#   extend ActiveModel::Naming
#   include ActiveModel::Conversion
#   attr_accessor  :generatedAtTime, :season, :startedAtTime, :endedAtTime, :atLocation, :wasAssociatedWith, :conferenceAssociation, :conferenceName, :conferenceAbbreviation, :conferenceHomepage, :conferenceProceeding
# conference_item_rdf_datastream
#   rdf_subject { |ds|


    end
  }
  rdf_type rdf_type RDF::BIBO.Proceedings
  rdf_type rdf_type RDF::PROV.Entity
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
    solr_doc[Solrizer.solr_name("desc_metadata__issue", :displayable)] = self.issue.first
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

  rdf_subject { |ds|ConferenceAttribution
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


class ConferenceAttribution
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



# class ConferenceRdfDatastream < ActiveFedora::NtriplesRDFDatastream
#   #include ModelHelper
#
#   attr_accessor :title, :subtitle, :abstract, :subject, :keyword, :worktype, :medium, :language, :publicationStatus, :reviewStatus, :license, :dateCopyrighted, :rightsHolder, :rightsHolderGroup, :rights, :rightsActivity, :creation, :funding, :publication
#
#
#   rdf_type rdf_type RDF::PROV.Entity
#   map_predicates do |map|
#     #-- title --
#     map.title(:in => RDF::DC)
#     #-- subtitle --
#     map.subtitle(:in => RDF::DAMS)
#     #-- abstract --
#     map.abstract(:in => RDF::DC)
#     #-- subject --
#     map.subject(:in => RDF::DC, class_name:"MadsSubject")
#     #-- keyword --
#     map.keyword(:in => RDF::CAMELOT)
#             #-- type --
#             map.worktype(:to=>"type", :in => RDF::DC, class_name:"WorkType")
#             #-- medium --
#             map.medium(:in => RDF::DC)
#     #-- language --
#     map.language(:in => RDF::DC, class_name:"MadsLanguage")
#     # -- documentation status --
#     #TODO: Check if this is used. May be replaced by one in conference activity
#     map.publicationStatus(:to => "DocumentStatus", :in => RDF::BIBO)
#     # -- review status --
#     #TODO: Check if this is used. May be replaced by one in conference activity
#     map.reviewStatus(:in => RDF::ORA)
#     # -- rights activity --
#     map.license(:in => RDF::DC, class_name:"LicenseStatement")
#     map.dateCopyrighted(:in => RDF::DC)
#     map.rightsHolder(:in => RDF::DC)
#     map.rightsHolderGroup(:in => RDF::ORA)
#     map.rights(:in => RDF::DC, class_name:"RightsStatement")
#     map.rightsActivity(:in => RDF::PROV, :to => "hadActivity", class_name:"RightsActivity")
#     # -- creation activity --
#     # TODO: link with Fedora person objects
#     map.creation(:to => "hadCreationActivity", :in => RDF::ORA, class_name:"CreationActivity")
#     # -- funding activity --
#     # TODO: Lookup and link with Fedora funder objects
#     map.funding(:to => "isOutputOf", :in => RDF::FRAPO, class_name:"FundingActivity")
#     #-- conference activity --
#     map.conference(:to => "hadConferenceActivity", :in => RDF::ORA, class_name:"ConferenceActivity")
#     #-- publication activity --
#     map.publication(:to => "hadPublicationActivity", :in => RDF::ORA, class_name:"PublicationActivity")
#     # -- Commissioning body --
#     # TODO: Nested attributes using Prov
#     #-- source --
#     # TODO: Nested attributes of name, homepage and uri - one to many
#
#   end
#   accepts_nested_attributes_for :language
#   accepts_nested_attributes_for :subject
#   accepts_nested_attributes_for :worktype
#   accepts_nested_attributes_for :license
#   accepts_nested_attributes_for :rights
#   accepts_nested_attributes_for :rightsActivity
#   accepts_nested_attributes_for :creation
#   accepts_nested_attributes_for :funding
#   accepts_nested_attributes_for :publication
#   accepts_nested_attributes_for :conference
#
#   def to_solr(solr_doc={})
#     solr_doc[Solrizer.solr_name("desc_metadata__title", :stored_searchable)] = self.title
#     solr_doc[Solrizer.solr_name("desc_metadata__subtitle", :stored_searchable)] = self.subtitle
#     solr_doc[Solrizer.solr_name("desc_metadata__abstract", :stored_searchable)] = self.abstract
#     solr_doc[Solrizer.solr_name("desc_metadata__keyword", :stored_searchable)] = self.keyword
#     solr_doc[Solrizer.solr_name("desc_metadata__medium", :stored_searchable)] = self.medium
#     solr_doc[Solrizer.solr_name("desc_metadata__publicationStatus", :stored_searchable)] = self.publicationStatus
#     solr_doc[Solrizer.solr_name("desc_metadata__reviewStatus", :stored_searchable)] = self.reviewStatus
#     #solr_doc[Solrizer.solr_name("dateCopyrighted", :stored_searchable, type: :date)] = self.dateCopyrighted
#     # Need to validate data and convert it to proper date format before indexing as date
#     solr_doc[Solrizer.solr_name("desc_metadata__dateCopyrighted", :stored_searchable)] = self.dateCopyrighted
#     solr_doc[Solrizer.solr_name("desc_metadata__rightsHolder", :stored_searchable)] = self.rightsHolder
#     solr_doc[Solrizer.solr_name("desc_metadata__rightsHolderGroup", :stored_searchable)] = self.rightsHolderGroup
#     # Index the type of work
#     self.worktype.each do |w|
#       already_indexed = []
#       unless w.typeLabel.empty? || already_indexed.include?(w.typeLabel.first)
#         w.to_solr(solr_doc)
#         already_indexed << w.typeLabel.first
#       end
#     end
#     # Index each language individually
#     self.language.each do |l|
#       already_indexed = []
#       unless l.languageLabel.empty? || already_indexed.include?(l.languageLabel.first)
#         l.to_solr(solr_doc)
#         already_indexed << l.languageLabel.first
#       end
#     end
#     # Index each subject individually
#     self.subject.each do |s|
#       already_indexed = []
#       unless s.subjectLabel.empty? || already_indexed.include?(s.subjectLabel.first)
#         s.to_solr(solr_doc)
#         already_indexed << s.subjectLabel.first
#       end
#     end
#     # Index each creator individually
#     self.creation.each do |c|
#       c.to_solr(solr_doc)
#     end
#     # Index each license individually
#     self.license.each do |l|
#         l.to_solr(solr_doc)
#     end
#     # Index each publication individually
#     self.publication.each do |p|
#         p.to_solr(solr_doc)
#     end
#     # Index each conference individually
#     self.conference.each do |p|
#         p.to_solr(solr_doc)
#     end
#     # Index each funding individually
#     self.funding.each do |f|
#         f.to_solr(solr_doc)
#     end
#     solr_doc
#   end
#
#   #TODO: Add FAST authority list later
#   #begin
#   #  LocalAuthority.register_vocabulary(self, "subject", "lc_subjects")
#   #  LocalAuthority.register_vocabulary(self, "language", "lexvo_languages")
#   #  LocalAuthority.register_vocabulary(self, "tag", "lc_genres")
#   #rescue
#   #  puts "tables for vocabularies missing"
#   #end
# end
#
