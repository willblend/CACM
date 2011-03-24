require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  scenario :users
  
  it "should override .admin?" do
    user = users(:admin)
    user.should be_admin # == .admin?
  end
    
  it "should override .developer?" do
    user = users(:developer)
    user.should be_developer # == .developer?
  end

end
