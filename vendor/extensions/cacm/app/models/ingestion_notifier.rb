class IngestionNotifier < ActionMailer::Base
    
  def notification(feed, runtime, frequency)
    from          ExceptionNotifier.email_from
    recipients    ExceptionNotifier.email_to
    subject       "Ingestion taking longer than expected"
    body          :feed => feed, :runtime => runtime, :frequency => frequency
    content_type  'text/plain'
  end
  
end