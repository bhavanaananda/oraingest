
# FIXME: ugly hack to get Solr working with Kaminari
class RSolr::Response::PaginatedDocSet
  attr_reader :limit_value
end



class ReviewingController < ApplicationController

  Filter = Struct.new(:facet, :value, :predicate)
  before_filter :restrict_access_to_reviewers

  def index



    backup_filter = Filter.new(:STATUS, :Claimed, :NOT)
    default_filter_1 = Filter.new(:STATUS, :Claimed)
    default_filter_2 = Filter.new(:CURRENT_REVIEWER, current_user.email)

    # @filters is an Array of Hashes that
    # keeps track of all the facets we filter on
    @filters = []

    @@solr_connection ||= RSolr.connect url: Rails.application.config.solr[Rails.env]['url']

    @@solr_docs ||= []

    filters <<
      default_query = "#{SolrFacets.lookup(:STATUS)}:Claimed AND #{SolrFacets.lookup(:CURRENT_REVIEWER)}=#{current_user.email}"
      backup_query = "!#{SolrFacets.lookup(:STATUS)}:Claimed"

    if params[:facet] && params[:facet_name]
    end


    response = solr_search(backup_query,  params[:page] ? params[:page].to_i : 1)

    @docs_found = response['response']['numFound']
    if @docs_found < 1
      #TODO: no Solr records, render error page
    else
      @facets = response['facet_counts']['facet_fields']
      @docs_list = response['response']['docs']
    end



=begin


  results = params[:search] ? do_global_search(params[:search]) : 
      QueryStringSearch.new(@@solr_docs, @query_string).results

    @total_found = results.size

    # if default search query doesn't find anything, use backup query
    if (params[:q] == default_query) && results.size == 0
      redirect_to action: 'index', q: backup_query and return
    end


    @result_list = []
    kam_rows = 10
    kam_pages = (@total_found.to_f / kam_rows.to_f).ceil

    if results && results.size > 0
      @result_list = Kaminari.paginate_array(results, total_count: @total_found).page(params[:page]).per(kam_rows) 
  end
=end

    # @disable_search_form = true #stop ora search form appearing

    # respond_to do |format|
    #   format.html
    #   format.json {render :json => results.to_json}
    # end

  end


  def solr_search(query, page = 1)
    logger.info "Solr search query: #{query}"

    @@solr_connection.paginate page, 10, "select", params: {
      q: query,
      facet: true,
      'facet.field' => SolrFacets.values,
      'facet.limit' => 20,
      wt: "ruby"
    }

  end


  def do_global_search( search_term )
    joined_results = []
    Solrium.each do |nice_name, solr_name|
      qs= "#{nice_name.to_s.downcase}=#{search_term}"
      rs = QueryStringSearch.new(@@solr_docs, qs).results
      joined_results.concat( rs ) if rs.size > 0
    end
    joined_results
  end


  def build_query(filter_list)
    query = ""
    # filter_list.each do |filter|
    #   query = "#{SolrFacets.lookup(filter.facet)}:#{filter.value}"
    #   if %w[NOT not Not].include? filter.predicate.to_s
    #     query = query.prepend('!')
    #   end
    # end

    (0...filter_list.length).step(1).each do |index|
      filter = filter_list[index]
      query = "#{SolrFacets.lookup(filter.facet)}:#{filter.value}"
      if %w[NOT not Not].include? filter.predicate.to_s
        query = query.prepend('!')
      end
      query << " AND " unless index == filter_list.length - 1
    end

    query

  end


  # Creates a Hash where the key is the facet and the value is a Hash
  # containing the facet's constraints
  #
  # @param facet_hash [Hash] the Solr-style facet Hash in the {facet [Hash]:
  # constraints [Array]} style
  # @return [Hash] a Hash in the {facet [Hash]: constraints [Hash]} style
  def process_facets(facet_hash)
    facets = {}
    facet_hash.each do |facet, facet_constraints|
      # Solrium.reverse_lookup(facet)
      if facet_constraints.size > 0
        facets[facet] = convert_constraints_array(facet_constraints)
      end
    end
    facets
  end


  # Converts a Solr-style facet costraints array into a more
  # meaningful Hash
  #
  # @param constraints_arr [Array] a Solr-style facet costraints array
  # @return [Hash] a Hash in the {constraint_name: count} style
  def convert_constraints_array(constraints_arr)
    constraints_hash = {}
    constraints_arr.each_with_index do |x, idx|
      if idx.even?
        constraints_hash[x] = constraints_arr[idx+1]
      end
    end
    constraints_hash
  end



  def full_search_query(term)
    q_string = ""
    Solrium.values.each_with_index do |solr_field, i|
      q_string = q_string + "#{solr_field}:#{term}"
      q_string = q_string + " OR " unless i == Solrium.values.size - 1
    end
    q_string
  end

  def restrict_access_to_reviewers
    unless can? :review, :all
      raise  CanCan::AccessDenied.new("You do not have permission to review submissions.", :review_submissions, current_user)
    end
  end

end
