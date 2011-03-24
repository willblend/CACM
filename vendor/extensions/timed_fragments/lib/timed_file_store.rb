class TimedFileStore < ActionController::Caching::Fragments::FileStore
  
  def cache_valid?(name, expiry=nil)
    expiry ||= TimedFragmentsExtension::FRAGMENT_LIFETIME
    File.mtime(real_file_path(name)) >= expiry.ago
  rescue => e
    RAILS_DEFAULT_LOGGER.error(e.message)
    false
  end

  def read(name, expiry=nil)
    super(name) if cache_valid?(name, expiry)
  end

end