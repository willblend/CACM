class Subscription < ActiveRecord::Base

  validates_format_of :email, :with => DP::REGEXP::EMAIL, :allow_blank => true
  validates_presence_of :email, :if => proc { |sub| not sub.no_subscriptions? }

  has_many_polymorphs :subscribables, :from => [:subjects, :sections], :through => :subscribables_subscriptions

  # gets_alerts_mailer returns trus if the user is subscribed to any section or subject alerts.
  def gets_alerts_mailer?
    !subscribables.empty?
  end

  def mailer_this_week?(headlines)
    subscribables.each do |s|
      if !headlines[s].blank?
        return true
      end
    end
    
    return false
  end

  # no_subscriptions returns true if the user is not subscribed to anything, including
  # the TOC alerts.
  def no_subscriptions?
    subscribables.empty? && !toc
  end
  
  # TODO: subject_ids and section_ids could be rolled up
  def subject_ids=(*ids)
    ids.flatten!
    subjects = subscribables_subscriptions.find(:all, :conditions => { :subscribable_type => 'Subject' })
    subscribables_subscriptions.delete(subjects)
    subscribables.reload
    unless ids == [0]
      ids.delete('0')
      subscribables << Subject.find_all_by_id(ids)
    end
  end

  def section_ids=(*ids)
    ids.flatten!
    sections = subscribables_subscriptions.find(:all, :conditions => { :subscribable_type => 'Section' })
    subscribables_subscriptions.delete(sections)
    subscribables.reload
    unless ids == [0]
      ids.delete('0')
      subscribables << Section.find_all_by_id(ids)
    end
  end
  
  def toc
    source.client_subscribed?(self.client_id)
  end
  
  def toc=(t)
    # messy form-based setter
    @toc = case t
    when 1, '1', true, 'true' : true
    else false
    end
  end
    
  def after_initialize
    unless (e = source.subscription_email(self.client_id)).blank?
      self.email = e
    end
  end

  def after_save
    # always have to keep the email in sync...
    source.subscribe_client(self.client_id, self.email)
    # ...now unsubscribe from the CACM TOC alert if not selected.
    source.unsubscribe_client(self.client_id) unless @toc
    return true
  end

  private

    def source
      @source ||= Oracle::Subscription.new
    end

end
