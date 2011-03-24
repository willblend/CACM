class Oracle::Subscription
  include Oracle::Procedure

  # Subscribe a client to the CACM TOC Alert. Must pass an email; if the
  # subscriber is already on record with a different email, this procedure
  # updates the record.
  def subscribe_client(client,email)
    cursor = parse "BEGIN msf.acm_utils.manage_tocs(:publication, :cno, :action, :email, :cur_status, :status_dt, :r_str); end;"
    cursor.bind_param ':cno',   client.to_s
    cursor.bind_param ':email', email ||= ''
    cursor.bind_param ':action', 'ADD'
    exec cursor do
      cursor[':r_str'] == 'Ok'
    end
  end

  # Unscubscribe client from the CACM TOC Alert.
  def unsubscribe_client(client)
    cursor = parse "BEGIN msf.acm_utils.manage_tocs(:publication, :cno, :action, :email, :cur_status, :status_dt, :r_str); end;"
    cursor.bind_param ':cno',   client.to_s
    cursor.bind_param ':email', nil, String, 64
    cursor.bind_param ':action', 'DEL'
    exec cursor do
      cursor[':r_str'] == 'Ok'
    end
  end

  # Returns boolean based on sub status
  def client_subscribed?(client)
    cursor = parse "BEGIN msf.acm_utils.manage_tocs(:publication, :cno, :action, :email, :cur_status, :status_dt, :r_str); end;"
    cursor.bind_param ':cno',   client.to_s
    cursor.bind_param ':email', nil, String, 64
    cursor.bind_param ':action', 'STATUS'
    exec cursor do
      cursor[':cur_status'] == 'subscribed'
    end
  end
  
  # Returns email if one is on record (regardless of sub status)
  def subscription_email(client)
    cursor = parse "BEGIN msf.acm_utils.manage_tocs(:publication, :cno, :action, :email, :cur_status, :status_dt, :r_str); end;"
    cursor.bind_param ':cno',   client.to_s
    cursor.bind_param ':email', nil, String, 64
    cursor.bind_param ':action', 'STATUS'
    exec cursor do
      cursor[':email'].blank? ? nil : cursor[':email']
    end
  end

  private

    def exec(cursor, &block)
      cursor.bind_param ':publication', 'J79'
      cursor.bind_param ':cur_status', nil, String, 64
      cursor.bind_param ':status_dt',  nil, Date
      cursor.bind_param ':r_str',      nil, String, 64
      super(cursor, &block)
    end
end