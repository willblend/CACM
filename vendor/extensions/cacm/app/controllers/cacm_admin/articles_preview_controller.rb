class CacmAdmin::ArticlesPreviewController < ApplicationController  
  include CACM::DLSession
  radiant_layout "Standard"
  helper :articles

  def create
    current_member.authenticate_user(:user => CACM::ADMIN_USER, :passwd => CACM::ADMIN_PASS) unless current_member.indv?
    if @article = Article.find_by_id(params[:id])
      @article.attributes = params[:article]
    else
      @article = Article.new(params[:article])
    end
    render :template => 'articles/preview'
  end

end