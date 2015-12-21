module DashboardHelper

  # uses the type of an item to generate a corresponding CSS tag to be used in
  # the dashboard view
  #
  # @note returned tag must match the one found in styles.scss:
  # @param review_item [Hash] the review item (dataset/thesis/etc) to be processed
  # @return  [ String ] the generated tag, or an empty string if the argument is nil
  def get_type_tag(item_type)
    item_type ? item_type.downcase.gsub(%r{\s}, '-').prepend('tag-')
    : ""
  end

  # uses the status of an item to generate a corresponding CSS tag to be used # in the dashboard view
  #
  # @note (see #get_type_tag)
  # @param (see #get_type_tag)
  # @return (see #get_type_tag)
  def get_status_tag(item_status)
    item_status ? item_status.downcase.gsub(%r{\s}, '-').prepend('tag-')
    : ""
  end


  def search_status
  end

  def add_to_query(query_term)
    # CGI::parse doesn't grok commas as separators
    # so replace them with &
    query_string = ""
    if params[:q]
      query_hash = query_string_to_hash( params[:q] )
      unless query_hash.has_key? query_term.keys.first
        query_hash.merge!(query_term)
        # now convert back to query string
        query_string = query_hash_to_string(query_hash)
      end
    else
      query_string = query_term.to_query.gsub('&', ',')
    end
    query_string
  end

  def query_string_to_hash(qs)
    qs = qs.gsub(',', '&')
    query_hash = Hash[CGI.parse(qs).map {|key,values| [key.to_sym, values[0]||true]}]
  end

  def query_hash_to_string(qh)
    qh.to_query.gsub('&', ',')
  end


  def remove_from_query(key)
  	key = key.to_s.chomp('!').to_sym
  	query_string = ""
    if params[:q]
      query_hash = query_string_to_hash( params[:q] )
      query_hash.delete(key)
      # now convert back to query string
      query_string = query_hash_to_string(query_hash)
    else
      #TODO: if there are no params, this shouldn't be called
    end
    query_string
  end

  def sanitise_params_query_hash
    query_hash = {}

    if params[:query]
      CGI.parse(params[:query]).each do |k, v|
        if k.is_a? String
          query_hash[k.gsub(%r{[\[\]]}, '')] = v
        elsif k.is_a? Symbol
          query_hash[k] = v
        end
      end
    end

    query_hash
  end


end
