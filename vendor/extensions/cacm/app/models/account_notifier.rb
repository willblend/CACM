class AccountNotifier < ActionMailer::ARMailer
  def web_account_email(profile)
    @from            = "do-not-reply@cacm.acm.org"
    @subject         = "ACM Web Accounts : Email Confirmation"
    @sent_on         = Time.now
    @recipients      = profile.email
    @body[:token]    = profile.token
    @body[:to]       = profile.email
  end

  def new_account_email(account={})
    @from            = "do-not-reply@cacm.acm.org"
    @subject         = "ACM Web Accounts : Login Information"
    @sent_on         = Time.now
    @recipients      = account[:email]
    @body[:to]       = account[:email]
    @body[:username] = account[:username]
    @body[:password] = account[:password]
  end
end