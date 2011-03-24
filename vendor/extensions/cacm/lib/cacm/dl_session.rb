module CACM
  module DLSession

    def self.included(base)
      base.class_eval do
        before_filter :authenticate_by_ip
        helper_method :current_member
      end
    end
    
    # initializes and/or returns session object (which may represent an ACM member)
    # also available as a helper method in views
    def current_member
      session[:oracle] ||= Oracle::Session.new(request.remote_ip)
    end
    
    # set or destroy @current_member (session object)
    def current_member=(oracle_session)
      if oracle_session.is_a?(Oracle::Session)
        @current_member = session[:oracle] = oracle_session
      else
        @current_member = session[:oracle] = nil
      end
    end
    
    private

      # IP-based authentication check. is only run once per session; result is
      # stored internally within the session object.
      def authenticate_by_ip
        return true if CACM::CRAWLER_IPS.include?(request.remote_ip)
        return false if CACM::CRAWLER_AGENTS =~ request.user_agent
        current_member.authenticate_ip(request.remote_ip) if current_member.inst?.nil?
      end

  end
end