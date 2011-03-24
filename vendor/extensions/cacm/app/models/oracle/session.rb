class Oracle::Session
  include Oracle::Procedure

  attr_reader :inst_client, :indv_client, :session_id, :session_token, :error, :created_at, :ip
  
  def initialize(ip=nil)
    @created_at = Time.now
    @query_cache = {}
    @ip = ip
  end
  
  def authenticate_ip(addr=@ip)
    @ip = addr
    cursor = parse "BEGIN msf.acm_utils.log_by_ip(:app, :rip, :cno, :session_id, :session_token, :err_str); end;"
    cursor.bind_param ':rip',            @ip, String, 46
    cursor.bind_param ':cno',            nil, String, 32
    cursor.bind_param ':session_id',     nil, String, 32
    cursor.bind_param ':session_token',  nil, String, 32
    exec cursor do
      unless cursor[':cno'] == 'NO' || !cursor[':err_str'].blank?
        @inst_client = cursor[':cno']
        @session_id = cursor[':session_id']
        @session_token = cursor[':session_token']
        true
      else
        @inst_client = false
      end
    end
  end
  
  def authenticate_user(opts={})
    opts = HashWithIndifferentAccess.new(opts)
    opts[:ip]     ||= @ip
    opts[:client] ||= self.client
    cursor = parse "BEGIN msf.acm_utils.log_by_unamepwd(:app, :uname, :passwd, :rip, :cno, :session_id, :session_token, :err_str); end;"
    cursor.bind_param ':uname',          opts[:user],          String, 256
    cursor.bind_param ':passwd',         opts[:passwd],        String, 256
    cursor.bind_param ':rip',            opts[:ip],            String, 46
    cursor.bind_param ':cno',            opts[:client],        String, 32
    cursor.bind_param ':session_id',     nil,                  String, 32
    cursor.bind_param ':session_token',  nil,                  String, 32
    exec cursor do
      unless cursor[':cno'] == 'NO' || !cursor[':err_str'].blank?
        @indv_client = cursor[':cno']
        @session_id = cursor[':session_id']
        @session_token = cursor[':session_token']
        true
      else
        @indv_client = false
      end
    end
  end

  # see if session is still active on portal.acm.org. return true if user
  # is anonymous, as there won't be any session to expire.
  def fresh?
    return true if client.empty?
    cursor = parse "BEGIN msf.acm_utils.is_session_active(:cfid, :cftoken, :answer); end;"
    cursor.bind_param ':cfid', @session_id, String, 32
    cursor.bind_param ':cftoken', @session_token, String, 32
    cursor.bind_param ':answer', nil, String, 32
    exec cursor, false do
      cursor[':answer'] == 'YES'
    end
  end

  def refresh!
    cursor = parse "BEGIN msf.acm_utils.relogin(:app, :session_id, :session_token, :rip, :cno, :ipcno, :answer); end;"
    cursor.bind_param ':app', 'cacm'
    cursor.bind_param ':session_id',    @session_id,    String, 32
    cursor.bind_param ':session_token', @session_token, String, 32
    cursor.bind_param ':rip',           @ip,            String, 32
    cursor.bind_param ':cno',           @indv_client,   String, 32
    cursor.bind_param ':ipcno',       @inst_client||'', String, 32
    cursor.bind_param ':answer',        nil,            String, 32
    exec cursor, false do
      cursor[':answer'] == 'Ok'
    end
  end

  # general access check. second argument can be a fulltext type (:html, :pdf, &c)
  # in which case we see if that type is open or controlled. if no type is given,
  # we check the user's individual access rights for this article without regard
  # to fulltext-type.
  def can_access?(article, type = nil)
    return true unless article.is_a?(DLArticle)
    return true if CACM::CRAWLER_IPS.include?(@ip)
    @query_cache[article.id] = combined_access_check(article.doi, type) unless @query_cache.has_key?(article.id)
    @query_cache[article.id]
  end

  def client
    [@inst_client,@indv_client].select { |x| x.is_a?(String) }.join('.')
  end
  
  def inst?
    @inst_client && !@inst_client.blank?
  end
  
  def indv?
    @indv_client && !@indv_client.blank?
  end
  
  def name
    unless name_first.blank? && name_last.blank?
      "#{name_first} #{name_last}"
    else
      false
    end
  end

  def name_first
    return '' unless indv?
    @name_first ||= (account = Oracle::WebAccount.find(self.indv_client)) ? account.name_first : ""
  end
  
  def name_last
    return '' unless indv?
    @name_last ||= (account = Oracle::WebAccount.find(self.indv_client)) ? account.name_last : ""
  end

  def username
    return '' unless indv?
    @username ||= (account = Oracle::WebAccount.find(self.indv_client)) ? account.username : ""
  end
  
  protected
  
    def marshal_dump
      [@ip, @inst_client, @indv_client, @session_id, @session_token, @created_at, @name_first, @name_last, @username]
    end
  
    def marshal_load(args)
      [:ip, :inst_client, :indv_client, :session_id, :session_token, :created_at, :name_first, :name_last, :username].each_with_index do |attr,i|
        instance_variable_set("@#{attr}", args[i])
      end
      @query_cache = {}
    end
  
  private
  
    # we don't use formatted_access all the time because it becomes expensive to
    # figure out *which* format we should check on (e.g. an article may not have
    # html fulltext, so we fall back to the PDF, and so on)
    def combined_access_check(article, type = nil)
      type ? check_formatted_access(:article => article, :type => type) : check_access(:article => article)
    end

    # non-specific access check
    def check_access(opts={})
      opts = HashWithIndifferentAccess.new(opts)
      opts[:client] ||= self.client
      cursor = parse "BEGIN msf.acm_utils.chk_access_ctrl(:app, :cno, :id, :authorize, :offering_str, :offering_name_str, :err_str); end;"
      cursor.bind_param ':id',      opts[:article], String, 32
      cursor.bind_param ':cno',      opts[:client], String, 32
      cursor.bind_param ':authorize',          nil, String, 32
      cursor.bind_param ':offering_str',       nil, String, 2048
      cursor.bind_param ':offering_name_str',  nil, String, 2048
      exec cursor do
        cursor[':authorize'] == 'YES'
      end
    end

    # access by specific fulltext type
    def check_formatted_access(opts={})
      opts = HashWithIndifferentAccess.new(opts)
      opts[:client] ||= self.client
      opts[:type]   ||= 'html'
      cursor = parse "BEGIN msf.acm_utils.chk_access(:app, :cno, :id, :ft_type, :authorize, :offering_str, :offering_name_str, :err_str, :accesstype); end;"
      cursor.bind_param ':id',      opts[:article], String, 32
      cursor.bind_param ':cno',      opts[:client], String, 32
      cursor.bind_param ':ft_type', opts[:type].to_s, String, 32
      cursor.bind_param ':authorize',          nil, String, 32
      cursor.bind_param ':offering_str',       nil, String, 2048
      cursor.bind_param ':offering_name_str',  nil, String, 2048
      cursor.bind_param ':accesstype',         nil, String, 32
      exec cursor do
        cursor[':accesstype'] == 'open' || cursor[':authorize'] == 'YES'
      end
    end

    def exec(cursor, bind=true, &block)
      if bind
        cursor.bind_param ':app', 'cacm'
        cursor.bind_param ':err_str', nil, String, 256
      end
      super(cursor, &block)
    end

end