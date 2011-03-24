require File.dirname(__FILE__) + '/../../spec_helper'

describe Oracle::Session do
  before do
    @cursor = StubCursor.new
    @session = Oracle::Session.new
    Oracle.connection.raw_connection.stub!(:parse).and_return(@cursor)
  end
  
  it "should marshalize" do
    @cursor[':cno'] = 'CLIENT'
    @cursor[':session_id'] = 'ID'
    @cursor[':session_token'] = 'TOKEN'
    @session.authenticate_ip('123.456.78.90')
    @session.session_id.should eql('ID')
    
    data = Marshal.dump(@session)
    new_session = Marshal.load(data)
    new_session.session_id.should eql('ID')
    new_session.session_token.should eql('TOKEN')
    new_session.inst_client.should eql('CLIENT')
  end

  it "should unmarshalize without cache" do
    @session.send(:instance_variable_set, :@query_cache, { 1 => true })
    data = Marshal.dump(@session)
    new_session = Marshal.load(data)
    new_session.send(:instance_variable_get, :@query_cache).should == {}
  end
  
  describe "#initialize" do
    it "should set created_at" do
      @session.created_at.should be_close(Time.now, 1.second)
    end
    
    it "should set empty cache" do
      @session.send(:instance_variable_get, :@query_cache).should == {}
    end
    
    it "should take an IP" do
      s = Oracle::Session.new('127.0.0.1')
      s.ip.should eql('127.0.0.1')
    end
  end
  
  describe "#authenticate_ip" do
    before do
      @cursor[':cno'] = 'ABCDEF'
      @cursor[':session_id'] = 'HIJKL'
      @cursor[':session_token'] = 'PQRST'
      @session.authenticate_ip('123.456.78.90')
    end
    
    it "should set @inst_client" do
      @session.inst_client.should eql('ABCDEF')
    end
    
    it "should set @session_id" do
      @session.session_id.should eql('HIJKL')
    end
    
    it "should set @session_token" do
      @session.session_token.should eql('PQRST')
    end
    
    it "should set @ip" do
      @session.instance_variable_get(:@ip).should eql('123.456.78.90')
    end
    
    it "should return true if valid auth" do
      @cursor[':cno'] = 'YES'
      @session.authenticate_ip('123.456.78.90').should be_true
    end
    
    it "should return false if invalid auth" do
      @cursor[':cno'] = 'NO'
      @session.authenticate_ip('123.456.78.90').should be_false
    end
  end
  
  describe "#authenticate_user" do
    before do
      @cursor[':cno'] = 'ABCDE'
      @cursor[':session_id'] = 'HIJKL'
      @cursor[':session_token'] = 'PQRST'
      @session.authenticate_user(:user => 'user', :passwd => 'passwd')
    end
    
    it "should set @indv_client" do
      @session.client.should eql('ABCDE')
    end
    
    it "should set @session_id" do
      @session.session_id.should eql('HIJKL')
    end
    
    it "should set @session_token" do
      @session.session_token.should eql('PQRST')
    end
  end

  describe "#sql" do
    it "should parse SQL statement" do
      Oracle.connection.raw_connection.should_receive(:parse).with("STUB SQL").and_return(@cursor)
      @session.send(:parse, "STUB SQL")
    end
  end
  
  describe "#client" do
    it "should return an institute no." do
      @session.instance_variable_set :@inst_client, '12345'
      @session.client.should eql('12345')
    end
    
    it "should return an individual no." do
      @session.instance_variable_set :@indv_client, '67890'
      @session.client.should eql('67890')
    end
    
    it "should concat an institute and an individual" do
      @session.instance_variable_set :@inst_client, '12345'
      @session.instance_variable_set :@indv_client, '67890'
      @session.client.should eql('12345.67890')      
    end
  end
  
  describe "#fresh?" do
    it "should return true if session is active on ACM portal" do
      @session.instance_variable_set :@indv_client, '12345'
      @cursor[':answer'] = 'YES'
      @session.fresh?.should be_true
    end
    
    it "should return true id client isn't logged in" do
      @session.stub!(:client).and_return('')
      @session.fresh?.should be_true
    end
  end
  
  describe "#check_access" do
    it "should be true if user has a crawler IP" do
      @session.ip = CACM::CRAWLER_IPS.first
      @session.can_access?(DLArticle.new).should be_true
    end

    it "should skip lower level access checks if user has crawler IP" do
      @session.ip = CACM::CRAWLER_IPS.first
      @session.should_not_receive(:combined_access_check)
      @session.can_access?(DLArticle.new)
    end
  end
  
end