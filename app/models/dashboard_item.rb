class DashboardItem

  attr_reader :title, :abstract, :creator, :status, :type, :depositor,
    :reviewer, :date_published, :date_accepted, :id

  def initialize(solr_doc)
    @id = solr_doc.id
    @title = trim_text(solr_doc.title, 300)
    @abstract = trim_text(solr_doc.abstract, 300)
    @creator = solr_doc.creator
    @status = solr_doc.status
    @type = solr_doc.type
    @depositor = solr_doc.depositor
    @reviewer = solr_doc.current_reviewer
    @date_published = solr_doc.date_published
    @date_accepted = solr_doc.date_accepted
  end

  def is_it_claimed?
    self.status == 'Claimed'
  end


  def date
    if !self.date_published.empty?
      self.date_published
    elsif !self.date_accepted.empty?
      self.date_accepted
    else
      ""
    end
  end

  def date_type
    dt = ""
    if !self.date_published.empty?
      dt = "published"
    elsif self.date_published.empty? && !self.date_accepted.empty?
      dt = "accepted"
    end
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
