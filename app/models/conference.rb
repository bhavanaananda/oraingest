require "datastreams/workflow_rdf_datastream"
require "datastreams/conference_rdf_datastream"
#require "datastreams/relations_rdf_datastream"
#require "datastreams/conference_admin_rdf_datastream"
#require "person"
require "rdf"

class Conference < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Sufia::GenericFile::AccessibleAttributes
  #include Sufia::GenericFile::WebForm
  include Sufia::Noid
  include Hydra::ModelMethods
  #include WorkflowMethods
  #include BuildMetadata
  include DoiMethods


  attr_accessible *(ConferenceRdfDatastream.fields + [:permissions, :permissions_attributes, :workflows, :workflows_attributes])
 # attr_accessible *(DatasetRdfDatastream.fields + RelationsRdfDatastream.fields + [:permissions, :permissions_attributes, :workflows, :workflows_attributes] + DatasetAdminRdfDatastream.fields)

  before_create :initialize_submission_workflow

  before_save :remove_blank_assertions

  has_metadata :name => "descMetadata", :type => ConferenceRdfDatastream
  has_metadata :name => "workflowMetadata", :type => WorkflowRdfDatastream

  has_attributes :workflows, :workflows_attributes, datastream: :workflowMetadata, multiple: true
  has_attributes *ConferenceRdfDatastream.fields, datastream: :descMetadata, multiple: true

  has_many :conferenceItems,  :property=>:has_conference_item, :class_name=>"ConferenceItem"

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name('label')] = self.label
    #index_collection_pids(solr_doc)
    return solr_doc
  end

  def apply_permissions(depositor)
    prop_ds = self.datastreams["workflowMetadata"]
    rights_ds = self.datastreams["rightsMetadata"]
    depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
    if prop_ds
      prop_ds.depositor = depositor_id unless prop_ds.nil?
    end
    rights_ds.permissions({:person=>depositor_id}, 'edit') unless rights_ds.nil?
    rights_ds.permissions({:group=>"reviewer"}, 'edit') unless rights_ds.nil?
    return true
  end
  
  def to_jq_upload(title, size, pid, dsid)
    return {
      "name" => title, #self.title,
      "size" => size, #self.file_size,
      "url" => "/conferences/#{pid}/file/#{dsid}", #"/conference/#{noid}",
      "thumbnail_url" => thumbnail_url(title, '48'),#self.pid,
      "delete_url" => "/conferences/#{pid}/file/#{dsid}", #"/conference/#{noid}",
      "delete_type" => "DELETE"
    }
  end

  private
  
  def initialize_submission_workflow
    if self.workflows.empty?  
      wf = self.workflows.build(identifier:"MediatedSubmission")
      wf.entries.build(status:"Draft", date:Time.now.to_s)
    end
  end

  def remove_blank_assertions
    ConferenceRdfDatastream.fields.each do |key|
      if !["spatial"].include?(key)
        self[key] = nil if self[key] == ['']
      end
    end
  end

  def self.find_or_create(pid)
    begin
      Conference.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Conference.create({pid: pid})
    end
  end

  def thumbnail_url(filename, size)
    icon = "fileIcons/default-icon-#{size}x#{size}.png"
    begin
      mt = MIME::Types.of(filename)
      extensions = mt[0].extensions
    rescue
      extensions = []
    end
    for ext in extensions
      if Rails.application.assets.find_asset("fileIcons/#{ext}-icon-#{size}x#{size}.png")
        icon = "fileIcons/#{ext}-icon-#{size}x#{size}.png"
      end
    end
    icon
  end

end
