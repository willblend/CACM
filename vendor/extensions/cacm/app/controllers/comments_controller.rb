class CommentsController < CacmController

  def create
    @article = Article.find(params[:article])
    
    if params[:comment].blank?
      flash[:comment] = "Your comment was blank!"
    elsif current_member.indv? || verify_recaptcha(:message => "Please enter the two words in the ReCaptcha box")
      @article.comments << Comment.new(:comment => params[:comment], :client_id => current_member.indv_client)
      flash[:comment] = "Thank you for commenting. Your comment will be added to the site after being reviewed."
    else
      flash[:comment] = "Please enter the two words in the ReCaptcha box."
      flash[:comment_text] = params[:comment]
    end

    redirect_to request.request_uri # based on routing, this should be :article/comments but via GET e.g. Article#comments action
  end

end
