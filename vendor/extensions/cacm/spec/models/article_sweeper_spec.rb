require File.dirname(__FILE__) + '/../spec_helper'

describe ArticleSweeper do
  scenario :articles_base
  
  before do
    @article = Article.create(valid_article)
    @sweeper = ArticleSweeper.instance
  end
  
  it "should expire fragments on save" do
    @sweeper.should_receive(:expire_record)
    @article.save
  end
  
  it "should expire fragments on delete" do
    @sweeper.should_receive(:expire_record)
    @article.destroy
  end
  
  # Passes in isolation, but sweepers kill the other specs so they're turned off
  # in spec_helper. Uncomment and run in isolation to test behavior.
  
  # describe "#expire_record" do
  #   it "should match fragments" do
  #     fragment_path = ActionController::Base.fragment_cache_store.cache_path + "/#{@article.id}.cache"
  #     Dir.should_receive(:glob).with(ActionController::Base.fragment_cache_store.cache_path + "/**/*#{@article.id}*", File::FNM_DOTMATCH).and_return([fragment_path])
  #     FileUtils.should_receive(:rm_rf).with(fragment_path)
  #     @article.save
  #   end
  # end
end