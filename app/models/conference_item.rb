require "datastreams/workflow_rdf_datastream"
require "datastreams/conference_item_rdf_datastream"
require "datastreams/relations_rdf_datastream"
require "datastreams/conference_item_admin_rdf_datastream"
#require "person"
require "rdf"

class ConferenceItem < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Sufia::GenericFile::AccessibleAttributes
  #include Sufia::GenericFile::WebForm
  include Sufia::Noid
  include Hydra::ModelMethods
  include WorkflowMethods
  include BuildMetadata
  include DoiMethods

  attr_accessible *(ConferenceItemRdfDatastream.fields + RelationsRdfDatastream.fields + [:permissions, :permissions_attributes, :workflows, :workflows_attributes] + ConferenceItemAdminRdfDatastream.fields)

  before_create :initialize_submission_workflow

  before_save :remove_blank_assertions

  has_metadata :name => "descMetadata", :type => ConferenceItemRdfDatastream
  has_metadata :name => "workflowMetadata", :type => WorkflowRdfDatastream
  has_metadata :name => "relationsMetadata", :type => RelationsRdfDatastream
  has_metadata :name => "adminMetadata", :type => ConferenceItemAdminRdfDatastream
  has_file_datastream "content01"

  has_attributes :workflows, :workflows_attributes, datastream: :workflowMetadata, multiple: true
  has_attributes *ConferenceItemRdfDatastream.fields, datastream: :descMetadata, multiple: true
  has_attributes *RelationsRdfDatastream.fields, datastream: :relationsMetadata, multiple: true
  has_attributes *ConferenceItemAdminRdfDatastream.fields, datastream: :adminMetadata, multiple: true

  belongs_to :conferenceItem, :property=>:presentedAt, :class_name=>"Conference"

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
        "url" => "/conferenceitems/#{pid}/file/#{dsid}", #"/conferenceitem/#{noid}",
        "thumbnail_url" => thumbnail_url(title, '48'),#self.pid,
        "delete_url" => "/conferenceitems/#{pid}/file/#{dsid}", #"/conferenceitem/#{noid}",
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
    ConferenceItemRdfDatastream.fields.each do |key|
      self[key] = nil if self[key] == ['']
    end
  end

  def self.find_or_create(pid)
    begin
      ConferenceItem.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      ConferenceItem.create({pid: pid})
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
