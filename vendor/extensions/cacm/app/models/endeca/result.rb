module Endeca
  class Result < OpenStruct
    
    # if the default Endeca::Query config is used, the following attributes
    # will be available: bib_id, title, subtitle, main_parent_title, publication_date

    def url(session=nil)
      link = "http://portal.acm.org/citation.cfm?id=#{self.bib_id}&dl=ACM"
      link += "&CFID=#{session.session_id}&CFTOKEN=#{session.session_token}" if session.is_a?(Oracle::Session) and not session.client.blank?
      link
    end
    
    # cast String to Time for comparison
    def publication_date
      Time.parse self.table[:publication_date]
    end
    
    # auto-concat title and subtitle
    def title
      [self.table[:title], subtitle].compact.join(': ')
    end

  end
end