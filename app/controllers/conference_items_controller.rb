# -*- coding: utf-8 -*-
# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight_advanced_search'

# bl_advanced_search 1.2.4 is doing unitialized constant on these because we're calling ParseBasicQ directly
require 'parslet'  
require 'parsing_nesting/tree'

require "utils"

class ConferenceItemsController < ApplicationController
  before_action :set_conference_item, only: [:show, :edit, :update, :destroy, :revoke_permissions]
  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller
  include Sufia::Controller
  #include Sufia::FilesControllerBehavior
  # Include ORA search logic
  include Ora::Search::Defaults
  include Ora::Search::ViewConfiguration
  include Ora::Search::Facets
  include Ora::Search::IndexFields
  #include Ora::Search::ShowFields
  include Ora::Search::SearchFields
  #include Ora::Search::RequestHandlerDefaults
  include Ora::Search::SortFields

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  before_filter :authenticate_user!, :except => [:show, :citation]
  before_filter :has_access?
  # This applies appropriate access controls to all solr queriesconferenceItem
  ConferenceItemsController.solr_search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  ConferenceItemsController.solr_search_params_logic += [:exclude_unwanted_models]

  skip_before_filter :default_html_head

  # Catch permission errors
  rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
    if exception.action != :show && exception.action != :index
      redirect_to action: 'show', alert: "You do not have sufficient privileges to modify this conference item"
      #redirect_to action: 'show'
    elsif exception.action == :show
      redirect_to conference_items_path, alert: "You do not have sufficient privileges to read this conference item"
    elsif current_user and current_user.persisted?
      redirect_to conference_items_path, alert: exception.message
    else
      session["user_return_to"] = request.url
      redirect_to new_user_session_url, :alert => exception.message
      #redirect_to new_user_session_url
    end
  end

  def index
    redirect_to conference_items_path
  end

  def show
    authorize! :show, params[:id]
    @pid = params[:id]
    @files = contents
    @model = 'conferenceItem'
  end

  def new
    @pid = Sufia::Noid.noidify(SecureRandom.uuid)
    @pid = Sufia::Noid.namespaceize(@pid)
    @conferenceItem = ConferenceItem.new
    @files = []
    @conference = Conference.new
    @conferenceItem.conference = @conference
    @model = 'conferenceItem'
  end

  def edit
    authorize! :edit, params[:id]

    unless Sufia.config.next_workflow_status.keys.include?(@conferenceItem.workflows.first.current_status)
      raise CanCan::AccessDenied.new("Not authorized to edit while record is being migrated!", :read, ConferenceItem)
    end
    unless Sufia.config.user_edit_status.include?(@conferenceItem.workflows.first.current_status)
      authorize! :review, params[:id]
    end

    @pid = params[:id]
    @files = contents
    @model = 'conferenceItem'
  end

  def create
    @pid = params[:pid]
    @conferenceItem = ConferenceItem.find_or_create(@pid)
    @conferenceItem.apply_permissions(current_user)

    if params.has_key?(:files)
      create_from_upload(params)
    elsif params.has_key?(:conference_item)
      add_metadata(params[:conference_item], "")
    else
      format.html { render action:'edit' }
      format.json { render json:@conferenceItem.errors, status: :unprocessable_entity }
    end
  end

  def update
    @pid = params[:pid]
    redirect_field = ""
    if params.has_key?(:redirect_field)
      redirect_field = params[:redirect_field]
    end
    if params.has_key?(:files)
      create_from_upload(params)
    elsif conference_item_params
      add_metadata(params[:conference_item], redirect_field)
    else
      format.html { render action: 'edit' }
      format.json { render json: @conferenceItem.errors, status: :unprocessable_entity }
    end
  end

  def destroy
    authorize! :destroy, params[:id]
    if @conferenceItem.workflows.first.current_status == "Migrate"
      raise CanCan::AccessDenied.new("Not authorized to delete while record is being migrated!", :read, ConferenceItem)
    elsif @conferenceItem.workflows.first.current_status != "Draft" && @conferenceItem.workflows.first.current_status !=  "Referred"
       authorize! :review, params[:id]
    end
    @conferenceItem.destroy
    respond_to do |format|
      format.html { redirect_to conference_items_path }
      format.json { head :no_content }
    end
  end

  def recent
    if user_signed_in?conference_item
      # grab other people's documents
      (_, @recent_documents) = get_search_results(:q =>filter_not_mine,
                                        :sort=>sort_field, :rows=>5)
    else 
      # grab any documents we do not know who you are
      (_, @recent_documents) = get_search_results(:q =>'', :sort=>sort_field, :rows=>5)
    end
  end

  def recent_me
    if user_signed_in?
      (_, @recent_user_documents) = get_search_results(:q =>filter_mine,
                                        :sort=>sort_field, :rows=>50, :fields=>"*:*")
    end
  end

  def recent_me_draft
    if user_signed_in?
      (_, @conferenceItem) = get_search_results(:q =>filter_mine_draft,
                                        :sort=>sort_field, :rows=>50, :fields=>"*:*")
    end
  end

  def recent_me_not_draft
    if user_signed_in?
      (_, @submitted_conference_items) = get_search_results(:q =>filter_mine_not_draft,
                                        :sort=>sort_field, :rows=>50, :fields=>"*:*")
    end
  end

  def self.uploaded_field
#  system_create_dtsi
    solr_name('desc_metadata__date_uploaded', :stored_sortable, type: :date)
  end

  def self.modified_field      #logger.error "error #{@conferenceItem.inspect}\n"

    solr_name('desc_metadata__date_modified', :stored_sortable, type: :date)
  end

  def create_from_upload(params)
    # check error condition No files
    return json_error("Error! No file to save") if !params.has_key?(:files)
    file = params[:files].detect {|f| f.respond_to?(:original_filename) }
    if !file
      return json_error "Error! No file for upload", 'unknown file', :status => :unprocessable_entity
    elsif (empty_file?(file))
      return json_error "Error! Zero Length File!", file.original_filename
    #elsif (!terms_accepted?)
    #  return json_error "You must accept the terms of service!", file.original_filename
    else
      process_file(file)
    end
  rescue => error
    logger.error "GenericFilesController::create rescued #{error.class}\n\t#{error.to_s}\n #{error.backtrace.join("\n")}\n\n"
    json_error "Error occurred while creating file."
  ensure
    # remove the tempfile (only if it is a temp file)
    file.tempfile.delete if file.respond_to?(:tempfile)
  end

  def process_file(file)
    #Sufia::GenericFile::Actions.create_content(@@conferenceItem, file, file.original_filename, datastream_id, current_user)
    @conferenceItem.add_file(file, datastream_id, file.original_filename)
    save_tries = 0
    begin
      @conferenceItem.save!
    rescue RSolr::Error::Http => error
      logger.warn "GenericFilesController::create_and_save_generic_file Caught RSOLR error #{error.inspect}"
      save_tries+=1
      # fail for good if the tries is greater than 3
      raise error if save_tries >=3
      sleep 0.01
      retry
    end

    respond_to do |format|
      format.html {
        render :json => [@conferenceItem.to_jq_upload(file.original_filename, file.size, @conferenceItem.id, datastream_id)],
        :content_type => 'text/html',
        :layout => false
      }
      format.json {
        render :json => [@conferenceItem.to_jq_upload(file.original_filename, file.size, @conferenceItem.id, datastream_id)]
      }
    end
  rescue ActiveFedora::RecordInvalid => af
    flash[:error] = af.message
    json_error "Error creating generic file: #{af.message}"
  end

  def revoke_permissions
    authorize! :destroy, params[:id]
    if params.has_key?(:access) && params.has_key?(:name) && params.has_key?(:type)
      new_params = @conferenceItem.validatePermissionsToRevoke(params, @conferenceItem.workflowMetadata.depositor[0])
      respond_to do |format|
        if @conferenceItem.update(new_params)
          if can? :review, @conferenceItem
            format.html { redirect_to edit_conference_items_path(@conferenceItem), notice: 'Conference item was successfully updated.' }
            format.json { head :no_content }
          else
            format.html { redirect_to edit_conference_items_path(@conferenceItem), notice: 'Conference item was successfully updated.' }
            format.json { head :no_content }
          end
        # elsif can? :review, @conferenceItem
        else
          format.html { render action: 'edit' }
          format.json { render json: @conferenceItem.errors, status: :unprocessable_entity }
        end
      end
    # elsif can? :review, @conferenceItem
    else
      format.html { render action: 'edit' }
      format.json { render json: @conferenceItem.errors, status: :unprocessable_entity }
    end
  end


  def add_metadata(conference_item_params, redirect_field)
    if !@conferenceItem.workflows.nil? && !@conferenceItem.workflows.first.entries.nil?
      old_status = @conferenceItem.workflows.first.current_status
    else
      old_status = nil
    end
    # find or create the conference, if included in the params
    # if conference_item_params.has_key?(:presented_at) or conference_item_params.has_key?(:conference)
    #   @@conference, created = add_conference(conference_item_params)
    # end
    # conference_item_params[:conference] = nil
    # conference_item_params[:presented_at] = nil
    # if @conference
    #   conference_item_params[:presented_at] = @conference.id
    # end

    @conferenceItem.buildMetadata(conference_item_params, contents, current_user.user_key)
    if old_status != @conferenceItem.workflows.first.current_status
      @conferenceItem.perform_action(current_user.user_key)
    end
    respond_to do |format|
      if @conferenceItem.save
          format.html { redirect_to edit_conference_item_path(@conferenceItem), notice: 'Conference item was successfully updated.' , flash:{ redirect_field: redirect_field }}
          format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @conferenceItem.errors, status: :unprocessable_entity }
      end
    end
  end



  def add_conference(conference_item_params)
    @conference = nil
    created = false
    conf_pid = nil
    # Get the parameter and sanitize it
    if conference_item_params.has_key?(:presented_at) and !conference_item_params[:presented_at].empty?
      conf_pid = conference_item_params[:presented_at]
      if conf_pid == "new" || conf_pid.empty? || conf_pid == ""
        conf_pid = nil
      end
    end
    # Try to extract the conference
    if !conf_pid.nil?
      begin
        @conference = Conference.find(conf_pid)
      rescue ActiveFedora::ObjectNotFoundError
        conf_pid = nil
      end
    end
    # Mint a pid if one does not exist
    if conf_pid.nil?
      conf_pid = Sufia::Noid.noidify(SecureRandom.uuid)
      conf_pid = Sufia::Noid.namespaceize(conf_pid)
      created = true
    end
    #if (@conference.nil? or @conference.agreementType.first == "Individual") and conference_item_params.has_key?(:conference)
    if @conference.nil?  and conference_item_params.has_key?(:conference)
      conference_item_params = {}
      conference_item_params = conference_item_params[:conference]
      if @conference.nil?
        @conference = Conference.find_or_create(conf_pid)
        @conference.apply_permissions(current_user)
      end
      conference_item_params[:title] = "Conference for #{@conferenceItem.id}"
      #conference_item_params[:agreementType] = "Individual"
      conference_item_params[:contributor] = current_user.user_key
      @conference.buildMetadata(conference_item_params, [], current_user.user_key)
      if !@conference.save
        @conference = nil
      end
    end
    return @conference, created
  end


  def contents
    choicesUsed = @conferenceItem.datastreams.keys.select { |key| key.match(/^content\d+/) and @conferenceItem.datastreams[key].content != nil }
    files = []
    for dsid in choicesUsed
      files.push(@conferenceItem.to_jq_upload(@conferenceItem.datastreams[dsid].label, @conferenceItem.datastreams[dsid].size, @conferenceItem.id, dsid))
    end
    files
  end

  def datastream_id
    choicesUsed = @conferenceItem.datastreams.keys.select { |key| key.match(/^content\d+/) and @conferenceItem.datastreams[key].content != nil }
    begin
      "content%02d"%(choicesUsed[-1].last(2).to_i+1)
    rescue
      "content01"
    end
  end

  private
    def conference_item_params
    #  #params.require(:conference_item).permit(:title, :subtitle, :description, :abstract, {:keyword => []}, :medium, :numPages, :pages, :publicationStatus, :reviewStatus, :language, :language_attributes, :workflows, :workflows_attributes, :permissions, :permissions_attributes, :subject, :scheme, :elementList, :externalAuthority, :topicElement_attributes, :topicElement, :scheme_attributes)
    #  params.require(:conference_item).permit!
    params.require(:conference_item)
    end

  def set_conference_item
    @conferenceItem =ConferenceItem.find(params[:id])
  end

  protected

  # Limits search results just to GenericFiles
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters

  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:\"info:fedora/afmodel:ConferenceItem\""
  end

  def depositor
  #  #Hydra.config[:permissions][:owner] maybe it should match this config variable, but it doesn't.
    Solrizer.solr_name('depositor', :stored_searchable, type: :string)
  end

  def workflow_status
  #  #Hydra.config[:permissions][:owner] maybe it should match this config variable, but it doesn't.
    Solrizer.solr_name('all_workflow_statuses', :stored_searchable, type: :symbol)
  end

  def filter_not_mine 
    "{!lucene q.op=AND df=#{depositor}}-#{current_user.user_key}"
  end

  def filter_mine
    "{!lucene q.op=AND df=#{depositor}}#{current_user.user_key}"
  end

  def filter_mine_draft
    "{!lucene q.op=AND} #{depositor}:#{current_user.user_key} #{workflow_status}:Draft"
  end

  def filter_mine_not_draft
    "{!lucene q.op=AND} #{depositor}:#{current_user.user_key} -#{workflow_status}:Draft"
  end

  def sort_field
    "#{Solrizer.solr_name('system_create', :sortable)} desc"
  end

  def has_access?
    true
  end

  def json_error(error, name=nil, additional_arguments={})
    args = {:error => error}
    args[:name] = name if name
    #render additional_arguments.merge({:json => [args]})
  end

  def empty_file?(file)
    (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
  end

end
