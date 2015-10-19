require "net/http"

# FIXME: ugly hack to get Solr working with Kaminari
class RSolr::Response::PaginatedDocSet
  attr_reader :limit_value
end



class FredDashboardController < ApplicationController

  before_filter :restrict_access_to_reviewers

  def index

    @@solr_connection ||= RSolr.connect url: ENV['url']
    @@solr_docs ||= [] #list if SolrDoc documents

    total = @@solr_connection.select({:rows => 0})["response"]["numFound"]
    if total < 1
      #TODO: no Solr records, render error page
    end

    rows  = 100 # rows to retrieve at a time


    pages = (total.to_f / rows.to_f).ceil # round up
    (1..pages).each do |page|
      start = (page-1) * rows
      query_string = "/select?q=*%3A*&rows=#{rows}&start=#{start}&wt=ruby"
      # need to remove # from url, or it won't work
      sanitised_url = ENV['url'].gsub(%r{/#}, '')
      response = http_request(sanitised_url + query_string)
      if response.is_a? Net::HTTPSuccess 
        #body is a Hash wrapped in a String, so eval will give us the Hash
        solr_hash = eval(response.body) 
        @facets = process_facets( solr_hash['facet_counts']['facet_fields'] )
        solr_hash['response']['docs'].each do |solr_doc|
          @@solr_docs << SolrDoc.new(solr_doc)
        end
      else
        # TODO: deal with error in accessing Solr
      end
    end

    default_query = "status=Claimed,creator=#{current_user.email}"
    backup_query = "status!=Claimed"



	if params[:search]
		# just prevent the query string from being set
    elsif params[:q] && !params[:q].empty?
      @query_string = params[:q]
    elsif params[:q] && params[:q].empty?  
    	@query_string = 'all'
    elsif !params[:q]
      redirect_to action: 'index', q: default_query and return
    end

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

    @disable_search_form = true #stop ora search form appearing

    respond_to do |format|
      format.html
      format.json {render :json => results.to_json}
    end

  end


  def do_search(query)
    logger.info "Solr search query: #{query}"
    page = 1 unless params[:page]


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

  def http_request(url, limit = 10)

    raise NoMemoryError, 'HTTP redirect too deep' if limit == 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    if response.is_a? Net::HTTPSuccess 
      response
    elsif response.is_a? Net::HTTPRedirection 
      http_request(response['location'], limit - 1)
    else
      response.error!
    end    
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
