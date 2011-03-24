require File.dirname(__FILE__) + '/../spec_helper'

describe Role do
  before(:each) do
    @role = Role.new
  end

  it "should require a name" do
    @role.should_not be_valid
    @role.name = 'Role'
    @role.should be_valid
  end
  
  it "should add role methods to User on create" do
    user = User.new
    user.should_not respond_to(:new_role?)
    Role.create(:name => 'new_role')
    user.should respond_to(:new_role?)
  end
  
  it "should create a new role when registered" do
    Role.register :foo, :bar
    Role.find_by_name('foo').should_not be_nil
    Role.find_by_name('bar').should_not be_nil
  end
  
  it "should not duplicate a role when registering" do
    lambda {
      Role.register :admin
    }.should_not change(Role, :count)
  end

end
