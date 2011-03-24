class ArticleSweeper < ActionController::Caching::Sweeper

  observe Article

  def after_update(record)
    expire_record(record)
  end
  
  def after_destroy(record)
    expire_record(record)
  end

  protected

    def expire_record(record)
      # brute-force expiry of anything that *looks* related
      unless ActionController::Base.fragment_cache_store.cache_path.blank?
        %x{find "#{ActionController::Base.fragment_cache_store.cache_path}" -name "*#{record.id}*" -exec rm -rf '{}' \\;}
      end
    end

end
