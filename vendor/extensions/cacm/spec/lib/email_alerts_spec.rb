require File.dirname(__FILE__) + '/../spec_helper'

describe EmailAlerts do
  scenario :articles_base, :subscriptions, :sections, :subjects, :feeds, :feed_types

  before do
    Oracle::Subscription.send(:class_variable_set, :@@conn, StubCursor.new)
  end

  describe "#send_all" do
    describe "finding articles" do
      before do
        f = feeds(:cacm)
        f.feed_type_id = feed_types(:article).id
        f.save
        subscriptions(:basic).subscribables << sections(:opinion)
        subscriptions(:basic).subscribables << subjects(:artificial_intelligence)
      end
      
      it "should get all the articles from the past week from the correct sections" do
        ret = EmailAlerts.get_this_weeks_headlines(sections(:opinion))
        ret.size.should eql(sections(:opinion).articles.size)
      end
    
      it "should not include any articles from before a week ago" do
        s = sections(:opinion).articles.first
        s.approved_at = 1.month.ago
        s.save
        ret = EmailAlerts.get_this_weeks_headlines(sections(:opinion))
        ret.size.should eql(sections(:opinion).articles.size-1)
      end
    end

    describe "sending emails" do
      it "should send an email to someone who's subscribed to at least one section or subject" do
        subscriptions(:basic).subscribables << sections(:opinion)
        subscriptions(:basic).subscribables << subjects(:artificial_intelligence)

        a = Article.new(valid_article)
        a.sections << sections(:opinion)
        a.save
        a.feed.feed_type = FeedType.find_by_name("Article")
        a.feed.save
        a.approve!

        SubscriptionNotifier.should_receive(:deliver_email_alert)
        EmailAlerts.send_all
      end

      it "should not send an email to someone who isn't subscribed to any sections or subjects" do
        subscriptions(:basic).subscribables.clear
        SubscriptionNotifier.should_not_receive(:deliver_email_alert)
        EmailAlerts.send_all
      end
      
      it "should not send an email when there have been no updates to the subscriber's subscriptions in the past week" do
        sections(:opinion).articles.each do |a|
          a.approved_at = 1.month.ago
          a.save
          a.feed.feed_type = FeedType.find_by_name("Article")
          a.feed.save
        end
              
        subscriptions(:basic).subscribables << sections(:opinion)
        SubscriptionNotifier.should_not_receive(:deliver_email_alert)
        EmailAlerts.send_all
      end

      it "should validate the email before sending" do
        subscriptions(:basic).subscribables << sections(:opinion)
        subscriptions(:basic).subscribables << subjects(:artificial_intelligence)
        s = subscriptions(:basic)
        s.email = "gobbledygook"
        s.save(false)
        SubscriptionNotifier.should_not_receive(:deliver_email_alert)
        EmailAlerts.send_all
      end
    end
  end
end