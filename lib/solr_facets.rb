# This module is responsible for mapping between Solr-style facet names and
# sensible facet names for our views.
#

module SolrFacets
  def self.add_attrib(key,value)
    @facet_hash ||= {}
    @facet_hash[key]=value
  end

  def self.const_missing(key)
    @facet_hash[key]
  end

  def self.each
    @facet_hash.each {|key,value| yield(key,value)}
  end

  def self.values
    @facet_hash.values
  end

  # Gets the Solr field name, given its equivalent readable name.
  #
  # @param field [Symbol] the human-readable attribute, e.g. :title
  # @return [String] the corresponding Solr attribute e.g.
  # "desc_metadata__title_tesim"
  def self.lookup(field)
    @facet_hash.fetch(field.to_s.upcase.to_sym)
  end


  # Gets the readable attribute name, given its solr field name.
  #
  # @param field [String] the Solr field name, e.g.
  # "desc_metadata__title_tesim"
  # @return [Symbol] the corresponding human-readable attribute, e.g. :title
  def self.reverse_lookup(solr_field)
    @facet_hash.key(solr_field).to_s.downcase.to_sym
  end

  self.add_attrib :TYPE, "desc_metadata__type_sim"
  self.add_attrib :CREATOR, "desc_metadata__creator_sim"
  self.add_attrib :KEYWORD, "desc_metadata__keyword_sim"
  self.add_attrib :SUBJECT, "desc_metadata__subject_sim"
  self.add_attrib :STATUS, "MediatedSubmission_status_ssim"
  self.add_attrib :PUBLISHER, "desc_metadata__publisher_sim"
  self.add_attrib :CURRENT_REVIEWER,
    "MediatedSubmission_current_reviewer_id_ssim"

end
