class SubscriptionNotifier < ActionMailer::ARMailer
  # send an email alert to the subscriber
  def email_alert(subscription, html, plaintext, email_promo)
    @from               = "Communications of the ACM <do-not-reply@cacm.acm.org>"
    @subject            = "CACM Content Alert: #{Date.today.to_s :date}"
    @recipients         = subscription.email
    @body[:alerts]      = subscription.subscribables
    @body[:html]        = html
    @body[:plaintext]   = plaintext
    @body[:email_promo] = email_promo
  end
end