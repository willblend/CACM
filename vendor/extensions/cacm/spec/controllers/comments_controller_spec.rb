require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  scenario :sections

  before do
    @member = Oracle::Session.new
    controller.stub!(:current_member).and_return(@member)
    @article = mock_model(Article, :comments => [])
    Article.stub!(:find).and_return(@article)
    request.env["HTTP_REFERER"] = '/back'
  end

  it "should redirect if no member" do
    post :create, :article => '123', :comment => "Lorem ipsum"
    response.should redirect_to('/back')
  end

  it "should redirect if member unauthorized" do
    @member.stub!(:can_access?).and_return(false)
    post :create, :article => '123', :comment => "Lorem ipsum"
    response.should redirect_to('/back')
  end

  it "should not add blank comments" do
    @member.stub!(:can_access?).and_return(true)
    @member.stub!(:indv?).and_return(true)
    @article.comments.should_not_receive(:<<)
    post :create, :article => '123', :comment => ""
  end

  it "should create comment if member authorized" do
    @member.stub!(:can_access?).and_return(true)
    @member.stub!(:indv?).and_return(true)
    @article.comments.should_receive(:<<).with(an_instance_of(Comment))
    post :create, :article => '123', :comment => "Lorem ipsum"
  end

  it "should redirect to comments on create" do
    @member.stub!(:can_access?).and_return(true)
    @member.stub!(:indv?).and_return(true)
    post :create, :article => '123', :comment => "Lorem ipsum"
    response.should redirect_to(request.request_uri)
  end

  it "should populate profile id in comment" do
    @member.stub!(:can_access?).and_return(true)
    @member.stub!(:indv?).and_return(true)
    @member.stub!(:indv_client).and_return('999')
    Comment.should_receive(:new).with(hash_including(:client_id => '999'))
    post :create, :article => '123', :comment => "Lorem ipsum"
  end
end