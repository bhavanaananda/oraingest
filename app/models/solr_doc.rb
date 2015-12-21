class SolrDoc


  # any instance variables we want to expose to the world as-is, without
  # any manipulation, go here
  attr_reader :id


  # constructs a DashboardItem object based on a SolrResponse document.
  # Reads the properties defined in Solrium module.
  #
  # @param solr_response_item [SolrResponse] the hash-like representation
  # of a Solr document
  def initialize(solr_response_item)
    Solrium.each do |nice_name, solr_name|
      self.instance_variable_set("@#{nice_name.to_s.downcase}", solr_response_item[solr_name])
    end
  end


  def is_it_claimed?
    self.status == 'Claimed'
  end

  # define explicit getters for instance variables we want to refine
  # before exposing to the outside
  def title
    @title ? @title.first : ""
  end

  def abstract
    @abstract ? @abstract.first : ""
  end

  def creator
    @creator ? @creator.join(',') : ""
  end

  def contributor
    @contributor ? @contributor.join(',') : ""
  end  

  def status
    @status ? @status.first : ""
  end

  def type
    @type ? @type.first : ""
  end

  def depositor
    @depositor ? @depositor.first : ""
  end

  def current_reviewer
    @current_reviewer ? @current_reviewer.first : ""
  end

  def date_published
    @date_published ? @date_published.first : ""
  end

  def date_accepted
    @date_accepted ? @date_accepted.first : ""
  end

  def subject
    @subject ? @subject : ""
  end


end
