class EmailAlerts
  class << self
    def send_all
      starttime = Time.now
      CacmExtension::EMAIL_LOGGER.info("#{Time.now} BEGIN: Email Alerts")
      
      email_promo = Page.new.send :parse, '<r:snippet name ="newsletter_right_column_ads" />' rescue ""
      
      # gather all the subjects and sections that you can subscribe to
      @alerts = Subject.find(:all) | ['News', 'Opinion', 'Blog CACM', 'Careers'].collect {|s| Section.find_by_name(s)}

      html = {}
      plaintext = {}
  
      # and make a hash of each 
      @alerts.collect do |object|
        # get the headlines for this week
        headlines = get_this_weeks_headlines(object)

        CacmExtension::EMAIL_LOGGER.info("\t#{object.name}: #{headlines.length} headlines")

        # and pre-render them each as html/plaintext versions
        html[object], plaintext[object] = render_headlines(headlines, object)
        
      end
      
      # deliver our email alerts to our adoring fans
      send_alert_to_subscribers(html, plaintext, email_promo)
      CacmExtension::EMAIL_LOGGER.info("#{Time.now} END: Email Alerts (#{(Time.now - starttime).round} sec)")
      CacmExtension::EMAIL_LOGGER.flush
    end
  
    # get this week's headlines
    def get_this_weeks_headlines(object)
      # make sure one week ago is the same for all article queries
      lastweek = 1.week.ago

      # and that we're only emailing articles (not books, courses, etc.)
      article_feed_type = FeedType.find_by_name("Article")
        
      if object.name == "Opinion"
        object.articles.find(:all, :include => :feed, :conditions => ['approved_at > ? AND feed_type_id = ? AND articles_sections.section_id IN (?) AND state = (?)', lastweek, article_feed_type, [object.id, *object.children.map(&:id)], 'approved'])
      else
        object.articles.find(:all, :include => :feed, :conditions => ['approved_at > ? AND feed_type_id = ?', lastweek, article_feed_type])
      end    
    end
  
    # render the headlines with the correct links
    def render_headlines(headlines, object)
      # store all the headlines
      base_url = object.is_a?(Subject) ? "http://#{ActionMailer::Base.default_url_options[:host]}/browse-by-subject/#{object.to_param}" : "http://#{ActionMailer::Base.default_url_options[:host]}/#{object.to_param}"

      # collect all the headlines for this subject / section in HTML and plaintext
      if !headlines.blank?
        html = headlines.collect{ |h|
          # deal with opinion subsections
          if object.name == "Opinion"
            section = h.sections.find(:first, :conditions => ['section_id IN (?)', [object.id, *object.children.map(&:id)]])
            base_url = "http://#{ActionMailer::Base.default_url_options[:host]}/#{section.to_param}"
          end
          "<li style=\"margin-bottom: 0.2em;\"><a href=\"#{base_url}/#{h.to_param}\" style=\"color: #007DA7; text-decoration:none;\">#{h.title}</a></li>"
        }.join("\n")
        plaintext = headlines.collect{ |h|
          # deal with opinion subsections
          if object.name == "Opinion"
            section = h.sections.find(:first, :conditions => ['section_id IN (?)', [object.id, *object.children.map(&:id)]])
            base_url = "http://#{ActionMailer::Base.default_url_options[:host]}/#{section.to_param}"
          end
          " * #{h.title} - #{base_url}/#{h.to_param}"
        }.join("\n")
      end
    
      return html, plaintext
    end

    def send_alert_to_subscribers(html, plaintext, email_promo)
      total_subscriptions = 0
      invalid_emails = 0
      sent = 0
      
      Subscription.find(:all).each do |s|
        # for each subscriber, if s/he has any subscriptions and there's content for at least one of those subscriptions, send an email.
        total_subscriptions += 1
        if s.gets_alerts_mailer? && s.mailer_this_week?(plaintext)
          if (s.email.match(DP::REGEXP::EMAIL))
            SubscriptionNotifier.deliver_email_alert(s, html, plaintext, email_promo)
            sent += 1
          else
            # Validate all emails before delivering subject alerts. Assume Oracle will pass invalid addresses.
            CacmExtension::EMAIL_LOGGER.info("\t#{Time.now} INVALID EMAIL: #{s.email}")
            invalid_emails += 1
          end
        end
      end
      CacmExtension::EMAIL_LOGGER.info("#{Time.now} #{sent} Email Alerts sent, #{invalid_emails} invalid email addresses, #{total_subscriptions} total subscriptions")
      CacmExtension::EMAIL_LOGGER.flush
    end
    
  end # class << self
end
