class MagazinesController < ArticlesController

  def syndicate
    # the RSS feed contains the articles from the latest issue
    @vertical = Issue.find(:first, :order => 'issue_id DESC', :conditions => ['state = ?', 'approved'])
    super
  end
  
  CACM::FULL_TEXT_TYPES.each do |method|
    define_method method do
      @oracle_issue = Oracle::Issue.find(:first, :conditions => ['publication_id = (?) AND issue = (?) AND EXTRACT(YEAR FROM pub_date) = (?)',
                                                                  CACM::PUB_ID,
                                                                  params[:month],
                                                                  params[:year]])
      @vertical = Issue.find_by_issue_id(@oracle_issue.id)
      super if validate_slug
    end
  end

end