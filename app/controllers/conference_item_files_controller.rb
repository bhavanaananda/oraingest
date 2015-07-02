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

class ConferenceItemFilesController < ApplicationController
  before_action :set_conferenceItem, only: [:destroy]

  include Hydra::Controller::DownloadBehavior

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  before_filter :authenticate_user!
  before_filter :has_access?

  skip_before_filter :default_html_head

  # Catch permission errors
  rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
    if exception.action != :show
      redirect_to action: 'show', alert: "You do not have sufficient privileges to delete this file"
    elsif exception.action == :show
      redirect_to action: publications_path, alert: "You do not have sufficient privileges to view or download this file"
    elsif current_user and current_user.persisted?
      redirect_to action: publications_path, alert: exception.message
    else
      session["user_return_to"] = request.url
      redirect_to new_user_session_url, :alert => exception.message
    end
  end

  def show
    authorize! :show, params[:id]
    send_content(asset)
  end

  def destroy
    authorize! :destroy, params[:id]
    if @conferenceItem.workflows.first.current_status != "Draft" && @conferenceItem.workflows.first.current_status !=  "Referred"
       authorize! :review, params[:id]
    end
    if @conferenceItem.datastreams.keys.include?(params[:dsid])
      # To delete a datastream 
      @conferenceItem.datastreams[params[:dsid]].delete
      parts = @conferenceItem.hasPart
      #n = parts.index{ |val| val.id.to_s.include? params[:dsid] }
      #unless n.nil?
        #@@conferenceItem.hasPart[n].accessRights = nil
        #@@conferenceItem.hasPart[n] = nil
      #end
      @conferenceItem.hasPart = nil
      @conferenceItem.hasPart = parts.select { |val| not val.id.to_s.include? params[:dsid] }
      @conferenceItem.save
    end
    respond_to do |format|
      format.html { redirect_to conference_item__url }
      format.json { head :no_content }
    end
  end

  private
  def set_conference_item
    @conferenceItem = ConferenceItem.find(params[:id])
  end

  protected

  def depositor
  #  #Hydra.config[:permissions][:owner] maybe it should match this config variable, but it doesn't.
    Solrizer.solr_name('depositor', :stored_searchable, type: :string)
  end

  def has_access?
    true
  end

  def json_error(error, name=nil, additional_arguments={})
    args = {:error => error}
    args[:name] = name if name
    #render additional_arguments.merge({:json => [args]})
  end

  def datastream_to_show
    ds = asset.datastreams[params[:dsid]] if params.has_key?(:dsid)
    raise "Unable to find a datastream for #{asset}" if ds.nil?
    ds
  end

end
