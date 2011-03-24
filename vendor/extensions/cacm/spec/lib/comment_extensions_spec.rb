require File.dirname(__FILE__) + '/../spec_helper'

describe CACM::CommentExtensions do
  scenario :cacm_articles
  
  describe "Comments_Extension#owner" do

    it "should return the username if there is no last name or first name" do
      comment = Comment.create({:comment => "comment_body", :commentable_id => "6",:commentable_type  => "Article", :client_id => "656452"})
      comment.stub!(:name_first).and_return("")
      comment.stub!(:name_last).and_return("")
      comment.stub!(:username).and_return("Jack Shepard")
      comment.owner.should eql("Jack Shepard")
    end
    
    it "should return the first name only if there is no last name" do
      comment = Comment.create({:comment => "comment_body", :commentable_id => "6",:commentable_type  => "Article", :client_id => "656452"})
      comment.stub!(:name_first).and_return("Hugo")
      comment.stub!(:name_last).and_return("")
      comment.stub!(:username).and_return("Jack Shepard")
      comment.owner.lstrip.rstrip.should eql("Hugo")
    end
    
    it "should return the last name only if there is no last name" do
      comment = Comment.create({:comment => "comment_body", :commentable_id => "6",:commentable_type  => "Article", :client_id => "656452"})
      comment.stub!(:name_first).and_return("")
      comment.stub!(:name_last).and_return("Kwon")
      comment.stub!(:username).and_return("Jack Shepard")
      comment.owner.lstrip.rstrip.should eql("Kwon")
    end
    
    it "should return the first name only if there is no last name" do
      comment = Comment.create({:comment => "comment_body", :commentable_id => "6",:commentable_type  => "Article", :client_id => "656452"})
      comment.stub!(:name_first).and_return("Benjamin")
      comment.stub!(:name_last).and_return("Linus")
      comment.stub!(:username).and_return("Jack Shepard")
      comment.owner.should eql("Benjamin Linus")
    end
    
  end
  
  describe 'Counter cache' do
    before do
      @article = articles(:cacm_article)
      @comment = @article.comments.create(:comment => 'comment', :client_id => '123456')
    end
    
    it "should increment on approve" do
      lambda {
        @comment.approve!
        @article.reload
      }.should change(@article, :comments_count).by(1)
    end
    
    it "should decrement when leaving approved" do
      @comment.approve!
      @article.reload
      lambda {
        @comment.reject!
        @article.reload
      }.should change(@article, :comments_count).by(-1)
    end
    
    it "should decrement when deleting an approved article" do
      @comment.approve!
      @article.reload
      lambda {
        @comment.destroy
        @article.reload
      }.should change(@article, :comments_count).by(-1)
    end
  end
  
end