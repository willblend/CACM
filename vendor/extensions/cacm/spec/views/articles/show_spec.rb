require File.dirname(__FILE__) + '/../../spec_helper'

describe '/articles/barrier' do
  scenario :sections, :cacm_articles
  
  before do
    @oracle = stub_everything(:oracle)
    @article = articles(:cacm_article)
    @article.date = Date.today
    @article.stub!(:source).and_return(@oracle)
    assigns[:article] = @article
    template.stub!(:current_member).and_return(@oracle)
  end

  it "should render upsell when logged in but unauthorized" do
    @oracle.stub!(:client).and_return('CLIENT')
    @oracle.stub!(:can_access?).and_return(false)
    template.should_not_receive(:render).with(:partial => '/session/form')
    render '/articles/barrier'
  end
  
end