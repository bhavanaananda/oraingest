# require 'ora/data_doi'
require 'active_support/core_ext/hash/indifferent_access'
require 'builder'
require 'nokogiri'

class WorkflowPublisher

  attr_accessor :parent_model

  def initialize(model)
    @parent_model = model
  end

  def perform_action(current_user)
    wf_id = 'MediatedSubmission'
    # Mint a doi or check a DOI if doi_requested? and in review status
    mint_and_check_doi

    send_email(wf_id, current_user) if Rails.env.production?
    # publish record
    publish_record(wf_id, current_user)
  end

  private

  def mint_and_check_doi(wf_id='MediatedSubmission')
    status = true
    msg = []
    # Check if in a review status
    wf = @parent_model.workflows.select{|wf| wf.identifier.first == wf_id}.first
    unless Sufia.config.user_edit_status.include?(wf.current_status)
      # Mint a doi or check a DOI, if doi_requested?
      if @parent_model.model_klass == 'Dataset' && @parent_model.doi_requested? && !@parent_model.doi_registered?

        @parent_model.set_dataset_doi

      end
    end
    unless status
      @parent_model.workflowMetadata.update_status(Sufia.config.failure_status, msg)
    end
  end

  def send_email(wf_id, current_user)
    models = { 'Article' => 'articles', 'DatasetAgreement' => 'dataset_agreements', 'Dataset' => 'datasets', 'Thesis' => 'theses' }
    record_url = Rails.application.routes.url_helpers.url_for(:controller => models[@parent_model.model_klass], :action=>'show', :id => @parent_model.id)
    data = {'record_id' => @parent_model.id, 'record_url' => record_url, 'doi_requested'=>@parent_model.doi_requested?}
    if @parent_model.doi_requested? && !@parent_model.doi_registered?
      data['doi'] = @parent_model.doi(mint=false)
    end
    @parent_model.datastreams['workflowMetadata'].send_email(wf_id, data, current_user, @parent_model.model_klass)
  end

  def publish_record(wf_id, current_user)
    # Send pid and list of open datastreams to queue
    # If datastreams are empty, that means record is all dark
    #1 Check if ready to publish
    return unless ready_to_publish?(wf_id=wf_id)
    msg = []
    status = nil

    #2 check minimum metadata
    ans, msg2 = check_minimum_metadata
    msg = msg + msg2
    status = Sufia.config.failure_status unless ans

    #3 Add record to publish workflow
    unless status == Sufia.config.failure_status
      ans, msg2 = add_to_queue
      msg = msg + msg2
      status = Sufia.config.verified_status
    end
    @parent_model.workflowMetadata.update_status(status, msg)
  end

  def ready_to_publish?(wf_id='MediatedSubmission')
    wf = @parent_model.workflows.select{|wf| wf.identifier.first == wf_id}.first
    status = false
    if wf.nil?
      return status
    end
    unless Sufia.config.publish_to_queue_options.keys.include?(@parent_model.model_klass.downcase)
      return status
    end
    unless Sufia.config.publish_to_queue_options[@parent_model.model_klass.downcase].include?(wf.current_status)
      return status
    end
    occurences = wf.all_statuses.select{|s| s == wf.current_status}
    occurence = Sufia.config.publish_to_queue_options[@parent_model.model_klass.downcase][wf.current_status]['occurence']
    return (occurences.length == occurence) || occurence == 'all'
  end

  def check_minimum_metadata
    status = true
    msg = []
    # descMetadata has to exist
    unless @parent_model.datastreams.keys().include? 'descMetadata'
      status = false
      msg << 'No descMetadata available.'
    end
    # All of the access rights should be in place
    unless @parent_model.has_all_access_rights?
      status = false
      msg << 'Not all files or the catalogue record has embargo details'
    end

    # The metadata for registering DOI should exist
    if @parent_model.model_klass == 'Dataset' && @parent_model.doi_requested?
      unless @parent_model.doi_registered?
        payload = @parent_model.doi_data

        error = validate_required_fields(payload).blank?
        unless error.blank?
          status = false
          msg << error
        end
      end
    end

    return status, msg
  end

  REQUIRED_ATTRIBUTES = ['identifier', 'creator', 'title', 'publisher', 'publicationYear' ].freeze
  def validate_required_fields(payload)
    errors, error_msg = [], ""
    REQUIRED_ATTRIBUTES.each do |attr|
      errors << "#{attr}" if payload.with_indifferent_access[attr].try(:blank?)
    end

    if errors.any?
      error_msg = "The following attributes are missing: " + errors.join(", ")
      obj.workflowMetadata.update_status(Sufia.config.failure_status, error_msg)
      obj.save!

    end
    error_msg
  end

  def add_to_queue
    msg = []
    status = true
    open_access_content = @parent_model.list_open_access_content
    numberOfFiles = (open_access_content.select { |key| key.start_with?('content') }).length
    msg << "Open access datastreams: %s."%open_access_content.join(', ')
    if @parent_model.model_klass == 'Dataset'
      Resque.enqueue(DatabankPublishRecordJob, @parent_model.id.to_s, open_access_content, @parent_model.model_klass, numberOfFiles.to_s)
    else
      # Add to ora publish queue
      args = {
        'pid' => @parent_model.id.to_s,
        'datastreams' => open_access_content,
        'model' => @parent_model.model_klass,
        'numberOfFiles' => numberOfFiles.to_s
      }
      Resque.redis.rpush(Sufia.config.ora_publish_queue_name, args.to_json)
    end
    return status, msg
  end

end
