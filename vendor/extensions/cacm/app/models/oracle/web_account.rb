class Oracle::WebAccount
  include Oracle::Procedure

  attr_accessor :client, :name_first, :name_middle, :name_last, :username, :email, :type, :question, :token, :errors
  attr_writer :password, :password_confirm, :answer
  
  # For validations, check validate_before_* methods below -- quick & dirty implementation

  # Takes a hash of attrs and an optional block for class methods that need
  # to init a new instance
  def initialize(args={})
    @errors = ActiveRecord::Errors.new(self)
    args.each_pair do |k,v|
      self.send "#{k}=", "#{v}".strip
    end
    yield self if block_given?
    self
  end

  # Like ActiveRecord::Base.find. Returns an account instance,
  # or false if record not found.
  def self.find(client_no)
    cursor = parse "BEGIN msf.manage_accounts.client_info_lookup(:i_client_no, :o_first_name, :o_last_name, :o_username, :o_status); end;"
    cursor.bind_param ':i_client_no',   client_no.to_s
    cursor.bind_param ':o_first_name',  nil, String, 256
    cursor.bind_param ':o_last_name',   nil, String, 256
    cursor.bind_param ':o_username',    nil, String, 256
    exec cursor do
      unless cursor[':o_status'] == 'NONE'
        self.new :client => cursor[':i_client_no'], :username => cursor[':o_username'], :type => cursor[':o_type'], :name_first => cursor[':o_first_name'], :name_last => cursor[':o_last_name']
      end
    end
  end

  # clients and web accounts are not one-to-one with emails, unfortunately.
  # This function will return a list of all web_accounts associated with a given email.
  # For checking client records which do *not* have web_accounts, 
  # see Oracle::Member instead.
  def self.find_all_by_email(email_in)
    cursor = parse "BEGIN msf.manage_accounts.find_client(:i_email, :o_client_no, :o_client_type, :o_username, :o_list, :o_status); end;"
    cursor.bind_param ':i_email',       email_in
    cursor.bind_param ':o_client_no',   nil, String, 64
    cursor.bind_param ':o_client_type', nil, String, 64
    cursor.bind_param ':o_username',    nil, String, 64
    cursor.bind_param ':o_list',        nil, String, 2048
    exec cursor do
      if cursor[':o_status'] == 'ACCOUNT EXISTS'
        if cursor[':o_client_type'] == 'LIST' # split list into individual accounts
          cursor[':o_list'].split(';').map do |account|
            client, username, type = account.split(',')
            self.new(:client => client, :username => username, :type => type, :email => email_in)
          end
        else # populate account & return
          [self.new(:client => cursor[':o_client_no'], :username => cursor[':o_username'], :type => cursor[':o_client_type'], :email => email_in)]
        end
      end
    end
  end
  
  # .find_by_username is a little misleading. It's here so we can look up an
  # account's security question; unfortunately, it doesn't return any other
  # fields.
  def self.find_by_username(user)
    cursor = parse "BEGIN msf.manage_accounts.forgot_password(:i_username, :o_question, :o_answer, :o_status); end;"
    cursor.bind_param ':i_username',  user
    cursor.bind_param ':o_question',  nil, String, 256
    cursor.bind_param ':o_answer',    nil, String, 256
    exec cursor do
      if cursor[':o_status'] == 'DONE'
        self.new(:username => user, :question => cursor[':o_question'])
      end
    end
  end

  # Used for checking against duplicate usernames
  def self.username_exists?(username)
    cursor = parse "BEGIN msf.manage_accounts.find_username(:i_username, :o_status); end;"
    cursor.bind_param ':i_username', username
    exec cursor do
      cursor[':o_status'] == 'YES'
    end
  end

 # This is used for saving new accounts (in lieu of a single-step Account.create)
 # Because member and non-member accounts require a different procedure, the
 # logic is based on the presence/abscence of a client_no. Client number should
 # have been populated when we initially looked up this account by email --
 # or left blank if no client account matched.
  def save
    validate_before_create
    
    return false if self.errors.any?
    
    if self.client.blank?
      cursor = parse "BEGIN msf.manage_accounts.non_member_create_account(:i_action, :i_password, :i_question, :i_answer, :i_email, :i_first_name, :i_middle_name, :i_last_name, :o_username, :o_client_no, :o_created, :o_status); end;"
      cursor.bind_param ':i_first_name' , self.name_first
      cursor.bind_param ':i_middle_name', ''
      cursor.bind_param ':i_last_name'  , self.name_last
      cursor.bind_param ':o_client_no'  , nil, String, 7
    else
      cursor = parse "BEGIN msf.manage_accounts.create_account(:i_action, :o_username, :i_password, :i_question, :i_answer, :i_email, :i_client_no, :o_created, :o_status); end;"
      cursor.bind_param ':i_client_no', self.client
    end
    cursor.bind_param ':o_username' , nil, String, 64
    cursor.bind_param ':i_action'   , 'ADD'
    cursor.bind_param ':i_password' , @password
    cursor.bind_param ':i_email'    , self.email
    cursor.bind_param ':o_created'  , Time.now
    cursor.bind_param ':i_question' , self.question
    cursor.bind_param ':i_answer'   , @answer
    exec cursor do
      if cursor[':o_status'] == 'ADDED'
        self.username = cursor[':o_username']
        self.client   = cursor[':o_client_no']
        true
      end
    end
  end

  # Retrieve user's security question since it's not populated at init
  def question
    if @question.blank?
      cursor = parse "BEGIN msf.manage_accounts.forgot_password(:i_username, :o_question, :o_answer, :o_status); end;"
      cursor.bind_param ':i_username', self.username
      cursor.bind_param ':o_question', nil, String, 256
      cursor.bind_param ':o_answer',  nil, String, 256
      exec cursor do
        self.question = cursor[':o_question']
      end
    end
    @question
  end

  def answer(ans)
    validate_answer(ans)
  end

  # Since password is the only field we ever update once a record is saved, it
  # gets its own interface. New password can be passed in, or set ahead of
  # time with @account.password = 'newpassword'. Security answer must also be
  # set with @account.answer = 'topsecret'. The intent here is to allow this
  # object to accept these via params so we can call #update_password with minimal fuss.
  # Returns boolean.
  def update_password(passwd = @password)
    validate_before_update

    return false if self.errors.any?

    cursor = parse "BEGIN msf.manage_accounts.reset_password_with_answer(:i_username, :i_answer, :i_new_password, :o_status); end;"
    cursor.bind_param ':i_username', self.username
    cursor.bind_param ':i_answer', @answer, String, 256
    cursor.bind_param ':i_new_password', passwd, String, 32
    exec cursor do
      case cursor[':o_status']
      when 'DONE' : true
      when 'NOT FOUND' : false
      when 'ERROR'
        self.errors.add_to_base 'An error prevented us from resetting your password'
        false
      when 'SAME PASSWORD'
        self.errors.add :password, "can't be the same as your existing password"
        false
      end
    end
  end

  # only used for #reset_password
  def validate_before_update
    self.errors.clear
    if @password.blank?
      self.errors.add :password, "This is a required field."
    else
      self.errors.add :password, "Must be 6-32 characters." unless (6..32).include?(@password.length) unless self.errors.any? 
      self.errors.add :password, "Cannot be same as username." if @password == self.username unless self.errors.any? # i don't think this works. -amlw
      self.errors.add :password, "Cannot contain spaces." if @password =~ /\s/ unless self.errors.any? 
    end
    self.errors.add :answer, 'Your Security Question answer is incorrect.' unless validate_answer(@answer) or self.errors.any?
  end

  # used for create_member_account and create_non_member_account
  def validate_before_create
    self.errors.clear
    
    if @password.blank?
      self.errors.add :password, "can't be blank"
    else
      self.errors.add :password, "must be between 6 and 32 characters" unless (6..32).include?(@password.length)
      self.errors.add :password, "can't be the same as your username" if @password == self.username
      self.errors.add :password, "can't contain spaces" if @password =~ /\s/
    end

    if @password != @password_confirm
      self.errors.add :password, "the password and confirmation provided do not match"
    end
    
    if @question.blank?
      self.errors.add :question, "can't be blank"
    else
      self.errors.add :question, "can't exceed 256 characters" if @question.length > 256
    end
    
    if @answer.blank?
      self.errors.add :answer,   "can't be blank" if @answer.blank?
    else
      self.errors.add :answer,   "can't exceed 256 characters" if @answer.length > 256
    end
    
    # Catch empty inputs when creating a non-member account
    if self.client.blank?
      self.errors.add :name_first, "can't be blank" if self.name_first.blank?
      self.errors.add :name_first, "can't exceed 32 characters" if self.name_first && self.name_first.length > 32
      
      self.errors.add :name_last,  "can't be blank" if self.name_last.blank?
      self.errors.add :name_last, "can't exceed 32 characters" if self.name_last && self.name_last.length > 32
    end
  end

  private
    def exec(cursor, &block)
      return false unless valid?
      cursor.bind_param ':o_status', nil, String, 64
      super(cursor, &block)
    end

    def self.exec(cursor, &block)
      cursor.bind_param ':o_status', nil, String, 64
      super(cursor, &block)
    end

    def validate_answer(ans)
      cursor = parse "BEGIN msf.manage_accounts.forgot_password(:i_username, :o_question, :o_answer, :o_status); end;"
      cursor.bind_param ':i_username',  self.username
      cursor.bind_param ':o_question',  nil, String, 256
      cursor.bind_param ':o_answer',    nil, String, 256
      exec cursor do
        ans == cursor[':o_answer']
      end
    end

    def valid?
      errors.empty?
    end
end