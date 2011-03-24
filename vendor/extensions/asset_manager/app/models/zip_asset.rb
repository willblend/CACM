class ZipAsset < Asset
  self.file_types = %w{application/zip application/x-gzip}
  
  attr_accessor :successes, :failures
  
  # unzip? should default to false, otherwise we'll
  # end up extracting the archive on updates
  def unzip?
    self.unzip ||= false
  end
  
  def save_with_unzip
    @successes, @failures = [], []
    if unzip?
      extract_each do |f|
        asset = Asset.new(:file => f, :uploaded_by_id => self.uploaded_by_id)
        if asset.save
          @successes << asset
        else
          @failures << asset
        end
      end
      self.destroy
      @failures.empty?
    else
      save_without_unzip
    end
  end
  alias_method_chain :save,  :unzip
  
  def extract_each(&block)
    Zip::ZipFile.open(self.file.to_file.path) do |zip|
      zip.each do |file|
        next if (base = File.basename(file.name)) =~ %r(^\.) || !file.file?
        tempfile = File.join(RAILS_ROOT, 'tmp', 'paperclip', base)
        begin
          file.extract(tempfile)
          yield File.open(tempfile)
        rescue Zip::ZipError
          next
        ensure
          FileUtils.rm_rf(tempfile) if File.exists?(tempfile)
        end
      end
    end
  end
  
end