require File.dirname(__FILE__) + '/../../spec_helper'

describe Oracle::WebAccount do
  before do
    @cursor = StubCursor.new
    @account = Oracle::WebAccount.new
    Oracle.connection.raw_connection.stub!(:parse).and_return(@cursor)
  end
  
  describe "#initialize" do
    it "should take attrs" do
      a = Oracle::WebAccount.new(:name_first => 'Vaclav', :name_last => "Speezl-Ganglia")
      [a.name_first, a.name_last].should eql(%w(Vaclav Speezl-Ganglia))
    end
    
    it "should take a block" do
      a = Oracle::WebAccount.new do |account|
        account.name_first = 'Vaclav'
        account.name_last = 'Speezl-Ganglia'
      end
      [a.name_first, a.name_last].should eql(%w(Vaclav Speezl-Ganglia))
    end
  end

  describe ".find" do
    before do
      Oracle::WebAccount.stub!(:new).and_return(@account)
    end

    it "should return false if not found" do
      @cursor[':o_status'] = 'NONE'
      Oracle::WebAccount.find(12345).should be_false
    end

    it "should return an instance of Account if found" do
      @cursor[':o_status'] = nil
      Oracle::WebAccount.find(12345).should eql(@account)
    end
  end
  
  describe ".find_all_by_email" do
    before do
      @cursor[':o_client_no'] = 'client_no'
      @cursor[':o_username'] = 'user_name'
      @cursor[':o_client_type'] = 'ACM MEMBER'
    end
    
    it "should return false if none found" do
      @cursor[':o_status'] = 'NONE'
      Oracle::WebAccount.find_all_by_email('josh@digitalpulp.com').should be_false
    end

    it "should return single account if found" do
      @cursor[':o_status'] = 'ACCOUNT EXISTS'
      
      Oracle::WebAccount.find_all_by_email('josh@digitalpulp.com').size.should eql(1)
      new_account = Oracle::WebAccount.find_all_by_email('josh@digitalpulp.com').first
      new_account.client.should eql('client_no')
      new_account.username.should eql('user_name')
      new_account.email.should eql('josh@digitalpulp.com')
      new_account.type.should eql('ACM MEMBER')
    end
  end
  
  describe ".username_exists?" do
    it "should return true if found" do
      @cursor[':o_status'] = 'YES'
      Oracle::WebAccount.username_exists?('josh').should be_true
    end
    
    it "should return false if not found" do
      @cursor[':o_status'] = 'NO'      
      Oracle::WebAccount.username_exists?('josh').should be_false
    end
  end
  
  describe "#save" do
    before do
      @account.username = 'josh'
      @account.email = 'josh@vitamin-j.com'
      @account.question = '?'
      @account.answer = '!'
      @account.name_first = 'Josh'
      @account.name_last = 'French'
      @account.password = 'secret'
      @account.password_confirm = 'secret'
    end
    
    it "should call create_account if client is set" do
      @account.client = '123456'
      @account.should_receive(:parse).with(/manage_accounts.create_account/).and_return(@cursor)
      @account.save
    end
    
    it "should call non_member_create_account if client is not set" do
      @account.client = nil
      @account.should_receive(:parse).with(/manage_accounts.non_member_create_account/).and_return(@cursor)
      @account.save
    end
    
    it "sould return true if added" do
      @cursor[':o_status'] = 'ADDED'
      @account.save.should be_true
    end
    
    it "should return false if not added" do
      @cursor[':o_status'] = 'NOT ADDED'
      @account.save.should be_false
    end
  end
  
  describe "#question" do
    it "should return local answer" do
      @account.question = 'Local?'
      @account.question.should eql('Local?')
    end
    
    it "should fetch remote if local not stored" do
      @account.question = nil
      @cursor[':o_question'] = 'Remote?'
      @account.question.should eql('Remote?')
    end
  end
  
  describe "#update_password" do
    before do
      @account.stub!(:validate_before_update).and_return(true)
    end

    it "should return true if successful" do
      @cursor[':o_status'] = 'DONE'
      @account.update_password.should be_true
    end
    
    it "should invalidate password if duplicate" do
      @cursor[':o_status'] = 'SAME PASSWORD'
      @account.update_password
      @account.errors.on(:password).should_not be_empty
    end
    
    it "should invalidate base if error" do
      @cursor[':o_status'] = 'ERROR'
      @account.update_password
      @account.errors.on_base.should_not be_empty
    end
  end
  
  describe "#validate_before_update" do
    it "should validate password" do
      @account.password = nil
      @account.validate_before_update
      @account.errors.on(:password).should_not be_empty
    end
    
    it "should validate answer" do
      @cursor[':o_answer'] = 'old answer'
      @account.answer = 'old_answer'
      @account.validate_before_update
      @account.errors.on(:password).should_not be_empty
    end
  end
  
  describe ".find_by_username" do
    before do
      @cursor[':o_status'] = 'DONE'
      @cursor[':o_question'] = '?'
    end

    it "should locate an account" do
      account = Oracle::WebAccount.find_by_username('josh')
      account.username.should eql('josh')
    end

    it "should populate the question" do
      account = Oracle::WebAccount.find_by_username('josh')
      account.question.should eql('?')
    end

    it "should return false if nothing found" do
      @cursor[':o_status'] = 'NOT FOUND'
      Oracle::WebAccount.find_by_username('blah').should be_false
    end
  end
  
  describe "#validate_before_create" do
    before do
      @account.validate_before_create
    end
    
    # it "should validate username" do
    #   @account.errors.on(:username).should_not be_empty
    # end
    
    it "should validate password" do
      @account.errors.on(:password).should_not be_empty
    end
    
    it "should validate question" do
      @account.errors.on(:question).should_not be_empty
    end

    it "should validate answer" do
      @account.errors.on(:answer).should_not be_empty
    end
    
    it "should validate name" do
      @account.errors.on(:name_first).should_not be_empty
      @account.errors.on(:name_last).should_not be_empty
    end
  end

end