module CACM
  module SiteExtensions

    # Activate sessions on Radiant pages
    def self.included(base)
      base.class_eval do
        session :disabled => false
        include CACM::DLSession
        alias_method_chain :process_page, :session
        alias_method_chain :show_uncached_page, :etags
      end
    end
    
    # Assign session object before rendering a page
    def process_page_with_session(page)
      page.current_member = current_member
      process_page_without_session(page)
    end

    def show_uncached_page_with_etags(page)
      # generate an etag for radiant pages based on the page, the current member, and the current time down to the hour.
      # this will cause the etag to expire at the top of every hour or depending on the user's logged in/out state.
      # ideally this would be based on the uniqueness of the content in the page but from this high a level we don't
      # have convenient access to that.
      flashmsg = flash.nil? ? "" : flash.inspect rescue "" # just in case flash isn't defined
      etag = Digest::MD5.hexdigest("#{request.parameters['url']}#{current_member.indv_client}#{Time.now.year}#{Time.now.month}#{Time.now.day}#{Time.now.hour}#{flashmsg}")
      response.headers['ETag'] = etag
      show_uncached_page_without_etags(page)
    end

  end
end