require File.dirname(__FILE__) + '/../../spec_helper'

describe CacmAdmin::ArticlesPreviewController do
  scenario :users

  before do
    login_as :admin
  end

  describe "#create" do
    before do
      @article = Article.new(:title => 'original title', :short_description => 'original text')
    end

    it "should find an article if id passed" do
      Article.should_receive(:find_by_id).with('999')
      put :create, :id => 999
      response.should render_template('articles/preview')
    end

    it "should merge params with found article" do
      Article.should_receive(:find_by_id).with('999').and_return(@article)
      put :create, :id => 999, :article => { :title => 'preview title' }
      assigns(:article).title.should eql('preview title')
      assigns(:article).short_description.should eql('original text')
    end

    it "should show a preview if no id passed" do
      put :create, :article => { :title => 'preview title' }
      assigns(:article).title.should eql('preview title')
      response.should render_template('articles/preview')
    end
  end

end