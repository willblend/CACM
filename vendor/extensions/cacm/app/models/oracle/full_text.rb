class Oracle::FullText < Oracle
  set_table_name 'dldata.fulltext'
  set_inheritance_column nil
  belongs_to :article, :class_name => 'Oracle::Article', :foreign_key => :id
  include Oracle::Procedure
  
  def url(session=nil)
    ft_url =  self[:url].gsub(/\s+/, '%20')
    if session.is_a?(Oracle::Session)
      ft_url += "&CFID=#{session.session_id}&CFTOKEN=#{session.session_token}" unless session.client.blank?
      ft_url += "&ip=#{session.ip}" unless session.ip.blank?
    end
    ft_url
  end
  
  # gnarly memoized dynamic methods
  %w(open public controlled).each do |type|
    define_method "is_#{type}?" do
      unless instance_variables.include? "@#{type}"
        instance_variable_set "@#{type}", (check_formatted_access == type)
      end
      instance_variable_get "@#{type}"
    end
  end
  
  private
    def check_formatted_access
      cursor = parse "BEGIN msf.acm_utils.chk_access(:app, :cno, :id, :ft_type, :authorize, :offering_str, :offering_name_str, :err_str, :access_type); end;"
      cursor.bind_param ':id',           self[:id], String, 32
      cursor.bind_param ':ft_type',    self[:type], String, 32
      cursor.bind_param ':cno',                nil, String, 32
      cursor.bind_param ':authorize',          nil, String, 32
      cursor.bind_param ':offering_str',       nil, String, 2048
      cursor.bind_param ':offering_name_str',  nil, String, 2048
      cursor.bind_param ':access_type',        nil, String, 32
      cursor.bind_param ':app', 'cacm'
      cursor.bind_param ':err_str', nil, String, 256
      exec cursor do
        cursor[':access_type']
      end
    end

end