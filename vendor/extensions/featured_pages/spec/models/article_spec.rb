describe Article do
  before do
    @first = double("first_featured_article")
    @not_first = double("not_the_first_featured_article")

    it Article.stub!(:featured).and_return([@first, @not_first])
  end

  it "when removing the first featured article the first article should have its featured_article attribute set to false" do
    @first.should_receive(:update_attribute).with(:featured_article, false)
  end
end


