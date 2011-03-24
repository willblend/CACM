require File.dirname(__FILE__) + '/../spec_helper'

describe CommentSweeper do
  scenario :articles_base
  
  before do
    @article = Article.create(valid_article)
    @comment = Comment.create(:commentable => @article)
    @sweeper = CommentSweeper.instance
  end
  
  it "should expire associated article if comment is approved" do
    @sweeper.should_receive(:expire_record).with(@article)
    @comment.approve!
  end
  
  it "should do nothing if comment is rejected" do
    @sweeper.should_not_receive(:expire_record).with(@article)
    @comment.reject!
  end
  
  it "should do nothing on delete" do
    @sweeper.should_not_receive(:expire_record)
    @comment.destroy
  end

end