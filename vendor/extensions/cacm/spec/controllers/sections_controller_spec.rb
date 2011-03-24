require File.dirname(__FILE__) + '/../spec_helper'

describe SectionsController do
  scenario :sections
  
  before do
    @section = sections(:opinion)
    @article = @section.articles.first
  end
  
  describe "fulltext" do
    it "should assign @vertical" do
      get :fulltext, :article => @article.to_param, :section => @section
      assigns(:vertical).should eql(@section)
    end
    
    it "should show an article from the correct section" do
      get :fulltext, :article => @article.to_param, :section => @section
      assigns[:article].should eql(@article)
    end
    
    it "should not show an article from a different section" do
      lambda {
        get :fulltext, :article => @article.to_param, :section => sections(:careers)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "abstract" do
    before do
      @dlarticle = DLArticle.new(valid_article)
      @dlarticle.sections << @section
      @dlarticle.save
      @dlarticle.approve! #not sure why this has to be approved twice... the 1st 'approve' doesn't seem to work, though.
      @dlarticle.approve!
    end
    
    it "should assign @vertical if the article is a DLArticle" do
      get :abstract, :article => @dlarticle.to_param, :section => @section
      assigns(:vertical).should eql(@section)
    end

    it "should not assign @vertical if the article is not a DLArticle" do
      lambda {
        get :abstract, :article => @article.to_param, :section => sections(:careers)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should show an article from the correct section" do
      get :abstract, :article => @dlarticle.to_param, :section => @section
      assigns[:article].should eql(@dlarticle)
    end
    
    it "should not show an article from a different section" do
      lambda {
        get :abstract, :article => @dlarticle.to_param, :section => sections(:careers)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "syndicate" do
    it "should load section" do
      get :syndicate, :section => @section
      assigns(:vertical).should eql(@section)
    end
  end

end
