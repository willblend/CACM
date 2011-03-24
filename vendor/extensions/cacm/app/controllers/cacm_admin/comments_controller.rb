class CacmAdmin::CommentsController < ApplicationController
  include CACM::DLSession

  cache_sweeper :comment_sweeper

  def index
    current_member.authenticate_user(:user => CACM::ADMIN_USER, :passwd => CACM::ADMIN_PASS) unless current_member.indv?
    if params[:feed_id] && params[:feed_id] != ""
      @comments = Comment.find(:all, :conditions => ["articles.feed_id = (?) AND comments.state = (?)", params[:feed_id], "new"], :joins => "LEFT OUTER JOIN articles on comments.commentable_id = articles.id")
    else
      if params[:filter] && !params[:filter].blank?
        @comments = Comment.find(:all, :conditions => {:state => "new"}, :order => "created_at asc")
      else
        @comments = Comment.find(:all, :conditions => {:state => "new"}, :order => "commentable_id desc, created_at asc")
      end
    end
    @feed_options = Feed.find(:all, :select => 'id,name', :order => :name).map do |f| 
      [f.name + " (#{Comment.count(:all,:conditions => ["articles.feed_id = (?) AND comments.state = (?)", f.id,"new"],:joins => "LEFT OUTER JOIN articles on comments.commentable_id = articles.id")})", f.id]
    end
    
  end
  
  def edit
    @comment = Comment.find(params[:id])
  end
  
  def update
    @comment = Comment.find(params[:id])   
    if @comment.update_attribute(:comment,params[:comment][:comment])
      if params[:commit].downcase.include? 'approve'
        flash[:notice] = "The comment has been <strong>approved</strong>"
        @comment.approve!
        redirect_to :action => "index"
      elsif params[:commit].downcase.include? 'reject'
        flash[:notice] = "The comment has been <strong>rejected</strong>"
        @comment.reject!
        redirect_to :action => "index"
      else
        flash[:notice] = "The comment has been <strong>updated</strong>"
        redirect_to :action => "index"
      end
    else
      flash.now[:error] = 'Please correct the errors below.'
    end
  end
  
  def approve
    Comment.find(params[:id]).approve!
    flash[:notice] = "The comment has been <strong>approved</strong>"
    redirect_to :action => "index"
  end
  
  def reject
    Comment.find(params[:id]).reject!
    flash[:notice] = "The comment has been <strong>rejected</strong>"
    redirect_to :action => "index"
  end

end