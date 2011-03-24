require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController.subclass('StubController') {} do
  scenario :users

  it "should not show restrict_to block if user is unauthorized" do
    controller.stub!(:current_user).and_return(users(:developer))
    controller.restrict_to(:editor) { @str = 'set' }
    @str.should be_nil
  end

  it "should show restrict_to block if user is authorized" do
    controller.stub!(:current_user).and_return(users(:developer))
    controller.restrict_to(:developer) { @str = 'set' }
    @str.should eql('set')
  end

  it "should show restrict_to block if user is admin" do
    controller.stub!(:current_user).and_return(users(:admin))
    controller.restrict_to(:bogus_role) { @str = 'set' }
    @str.should eql('set')
  end
end