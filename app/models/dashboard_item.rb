class DashboardItem
  include ActiveModel::Model


  # any instance variables we want to expose to the world as-is, without
  # any mainpulation
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
    @title ? trim_text(@title.first, 300) : ""
  end

  def abstract
    @abstract ? trim_text(@abstract.first, 300) : ""
  end

  def creator
    @creator ? @creator.join('; ') : ""
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

  def reviewer
    @reviewer ? @reviewer.first : ""
  end

  def date
    if  @date_published && @date_published.size >  0
      @date_published.first
    elsif  @date_accepted && @date_accepted.size >  0
      @date_accepted.first
    else
      " "
    end
  end
  
  def date_type
    dt = " "
    dt = "published" if @date_published && @date_published.first
    dt = "accepted" if @date_accepted && @date_accepted.first && dt == " "
    dt
  end

  def tickets
    @rt_tickets ||= []
  end




  private

  # if the text exceeds the limit it will slice the text to the limit and append some continuation characters (...). If the text is less than the limit it is returned unchanged. Used to display text fields in the view
  #
  # @param txt [String] the text to trim
  # @param limit [FixNum] the limit to trim to
  # @return [String] the trimmed or untrimmed text
  def trim_text(txt, limit)
    if txt
      txt = (txt.size > limit) ?
        (txt.slice(0, limit ) + "...") :
        txt
    else
      txt = ""
    end
  end


end
