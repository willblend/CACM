require File.dirname(__FILE__) + '/../spec_helper'

describe SubjectsController do
  scenario :subjects
  
  before do
    @subject = subjects(:entertainment)
    @article = @subject.articles.first
  end

  describe "fulltext" do
    it "should assign @vertical" do
      get :fulltext, :article => @article.to_param, :subject => @subject
      assigns(:vertical).should eql(@subject)
    end

    it "should show an article from the correct section" do
      get :fulltext, :article => @article.to_param, :subject => @subject
      assigns[:article].should eql(@article)
    end
    
    it "should not show an article from a different section" do
      lambda {
        get :fulltext, :article => @article.to_param, :subject => subjects(:cats)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "abstract" do
    before do
      @dlarticle = DLArticle.new(valid_article)
      @dlarticle.subjects << @subject
      @dlarticle.save
      @dlarticle.approve! #not sure why this has to be approved twice... the 1st 'approve' doesn't seem to work, though.
      @dlarticle.approve!
    end
    
    it "should assign @vertical if the article is a dlarticle" do
      get :abstract, :article => @dlarticle.to_param, :subject => @subject
      assigns(:vertical).should eql(@subject)
    end

    it "should not assign @vertical if the article is not a dlarticle" do
      lambda {
        get :abstract, :article => @article.to_param, :subject => @subject
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should show an article from the correct section" do
      get :abstract, :article => @dlarticle.to_param, :subject => @subject
      assigns[:article].should eql(@dlarticle)
    end
    
    it "should not show an article from a different section" do
      lambda {
        get :abstract, :article => @dlarticle.to_param, :subject => subjects(:cats)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "syndicate" do
    it "should load subject" do
      get :syndicate, :subject => @subject
      assigns(:vertical).should eql(@subject)
    end
  end

end
