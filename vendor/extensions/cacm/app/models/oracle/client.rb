class Oracle::Client
  # Convenience class used to distinguish web_accounts from non-web memberships
  include Oracle::Procedure
  
  attr_accessor :email, :id, :type, :username
  
  # Just your basic i-wish-i-were-an-active-record initializer
  def initialize(args={})
    args.each_pair do |k,v|
      self.send "#{k}=", "#{v}".strip
    end
  end
  
  # Returns a client record if and only if no web_account is associated to this
  # client. The difference between FOUND and MULTIPLE FOUND does not affect
  # our logic, as the ACM will always return the record with the most access
  # if multiple clients are found.
  def self.find_by_email(email_in)
    cursor = parse "BEGIN msf.manage_accounts.find_client(:i_email, :o_client_no, :o_client_type, :o_username, :o_list, :o_status); end;"
    cursor.bind_param ':i_email',       email_in
    cursor.bind_param ':o_client_no',   nil, String, 64
    cursor.bind_param ':o_client_type', nil, String, 64
    cursor.bind_param ':o_username',    nil, String, 64
    cursor.bind_param ':o_list',        nil, String, 2048
    cursor.bind_param ':o_status',       nil, String, 64
    exec cursor do
      case cursor[':o_status']
      when 'FOUND', 'MULTIPLE FOUND'
        self.new :id => cursor[':o_client_no'], :username => cursor[':o_username'], :type => cursor[':o_client_type'], :email => email_in
      end
    end
  end

end