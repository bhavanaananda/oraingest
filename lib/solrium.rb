
  # This module is responsible for mapping between Solr-style field names and
  # sensible attribyte names for our objects and views. Can be used to 
  # quickly initialize classes, e.g. see DashboardItem 
  #

module Solrium
  def self.add_attr(key,value)
    @hash ||= {}
    @hash[key]=value
  end

  def self.const_missing(key)
    @hash[key]
  end

  def self.each
    @hash.each {|key,value| yield(key,value)}
  end


  # Gets the Solr field name, given its equivalent readable name
  # arguments if called repeatedly.
  #
  # @param field [Symbol] the human-readable attribute, e.g. :title
  # @return [String] the corresponding Solr attribute e.g. 
  # "desc_metadata__title_tesim"
  def self.find(field)
    @hash.fetch(field.to_s.upcase.to_sym)
  end

  self.add_attr :ID, 'id'
  self.add_attr :STATUS, 'MediatedSubmission_status_ssim'
  self.add_attr :TITLE, 'desc_metadata__title_tesim'
  self.add_attr :TYPE, 'desc_metadata__type_tesim'
  self.add_attr :ABSTRACT, 'desc_metadata__abstract_tesim'
  self.add_attr :DEPOSITOR, 'depositor_tesim'
  self.add_attr :DATE_PUBLISHED, 'desc_metadata__datePublished_tesim'
  self.add_attr :DATE_ACCEPTED, 'desc_metadata__dateAccepted_tesim'
  self.add_attr :CREATOR, 'desc_metadata__creatorName_tesim'
  self.add_attr :REVIEWER, 'MediatedSubmission_current_reviewer_id_ssim'
  self.add_attr :RT_TICKETS, 'MediatedSubmission_all_email_threads_ssim'
end

