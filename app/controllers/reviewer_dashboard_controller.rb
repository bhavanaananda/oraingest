require 'blacklight/catalog'
class ReviewerDashboardController < ApplicationController
  include  Sufia::DashboardControllerBehavior
  layout "sufia-two-column"    
  # Remove the solr_search_params_logic that we don't want applied 
  # (No advanced search & Don't apply the Hydra gated discovery, which filters out all things that don't list you in their permissions.)
  # See: https://github.com/projectblacklight/blacklight/wiki/Extending-or-Modifying-Blacklight-Search-Behavior
  ReviewerDashboardController.solr_search_params_logic = CatalogController.solr_search_params_logic - [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr, :add_access_controls_to_solr_params]
  # Add query filter
  solr_search_params_logic << :exclude_draft_and_approved
   
  before_filter :restrict_access_to_reviewers
  
  self.copy_blacklight_config_from(CatalogController)
  
  configure_blacklight do |config|
    # Extra Facets
    config.add_facet_field "MediatedSubmission_current_reviewer_id_ssim", :label => "Current Reviewer", :limit => 5
    config.add_facet_field "MediatedSubmission_all_reviewer_ids_ssim", :label => "All Reviewers", :limit => 5
   # config.add_facet_field "MediatedSubmission_status_ssim", :label => "Current status", :limit => 15
  end
  
  private
  
  def restrict_access_to_reviewers
    unless can? :review, :all
      raise Hydra::AccessDenied.new("You do not have permission to review submissions.", :review_submissions, params[:id])
    end 
  end
  
  # Limits search results just to GenericFile and Collection objects
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-submitted parameters
  def exclude_unwanted_models solr_parameters, user_parameters
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] <<
        "active_fedora_model_ssi:Article OR 
        active_fedora_model_ssi:Dataset OR 
        active_fedora_model_ssi:Thesis"
  end
  
  # Limits search results to exclude items whose Workflow status is not in Sufia.config.review_dashboard_status
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def exclude_draft_and_approved solr_parameters, user_parameters
    solr_parameters[:fq] ||= []
    (Sufia.config.workflow_status - Sufia.config.review_dashboard_status).each do |s|
      solr_parameters[:fq] << '-'+Solrizer.solr_name("MediatedSubmission_status", :symbol)+':'+s
    end
  end
  
  def current_user_claimed_tickets_count
    return 0 unless current_user
    facet = @response.facets.find {|f| f.name == 'MediatedSubmission_current_reviewer_id_ssim'}
    return 0 unless facet
    user_item = facet.items.find {|i| i.value == current_user.email}
    return 0 unless user_item
    user_item.hits
  end
  helper_method :current_user_claimed_tickets_count
  
end

