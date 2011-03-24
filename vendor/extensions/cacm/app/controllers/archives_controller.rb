class ArchivesController < CacmController
  
  helper_method :contextual_article_path
  helper CACM::ArchivesHelper  

  def index
  end

  def toc
    # generate an ETag for the TOC based on the month and year
    # also include the current user in case s/he logs in/out
    flashmsg = flash.nil? ? "" : flash.inspect rescue "" # just in case flash isn't defined
    etag = Digest::MD5.hexdigest("#{params[:month]}#{params[:year]}#{current_member.indv_client}#{flashmsg}")
    response.headers['ETag'] = etag

    @issue = Oracle::Issue.find(:first,
                                :conditions => ['publication_id = ? AND issue = ? AND EXTRACT(YEAR FROM pub_date) = ?',
                                                 CACM::PUB_ID,
                                                 params[:month],
                                                 params[:year]  ])

    raise ActiveRecord::RecordNotFound unless @issue && @issue.local && @issue.local.approved?
  end

  def year
  end

end