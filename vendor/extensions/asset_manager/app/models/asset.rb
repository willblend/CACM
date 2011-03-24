class Asset < ActiveRecord::Base
  # has_picker
  
  attr_accessor :unzip # here because this attr is set before
                       # any instance is cast to a ZipAsset
  
  # CONSTANTS
  EXPIRATION_LOOKAHEAD = 30.days
  
  class_inheritable_accessor :file_types
  self.file_types = []
  
  def self.inherited(klass)
    super(klass)
    
    klass.class_eval do
      def validate
        errors.add(:file_content_type, 'File type is not accepted') unless self.class.file_types.include?(self.file_content_type)
      end
    end
    
    # klass.validates_inclusion_of(:file_content_type, :in => klass.file_types, :message => 'is not an accepted file type', :allow_nil => true)
    define_method "#{klass.name.gsub('Asset', '').underscore}?" do
      is_a?(klass) or klass.file_types.include?(self.file_content_type) or self.file_content_type =~ /^#{klass.name.gsub('Asset', '')}/i
    end
  end
  
  set_inheritance_column :class_name
  
  # ASSOCIATIONS
  belongs_to :uploaded_by, :class_name => "User"

  # INTERFACES
  acts_as_modified
  
  has_attached_file :file,
                    :url => "/system/assets/:id_partition/:basename:style.:extension:cache_buster",
                    :path => ":rails_root/public/system/assets/:id_partition/:basename:style.:extension",
                    # ADDITIONAL OPTIONS
                    # ***only done for the CAE articles in CACM-- not to be rolled back into asset_manager!***
                    :styles => {
                      :thumb_square  => '48x48#',    # TBD, probably asset manager admin
                      :small_square  => "100x100>#", # listing
                      :medium_square => "160x160>#", # feature page
                      :medium        => "160>",      # asset manager admin edit screen
                      :large         => "250>"       # article page
                    }
                    #=> thumbnail options
                    # :default_url => ":class/missing_:style.png" #=> default replacement for missing images
                    # :default_style => :small #=> select a style other than original to show by default

  validate_on_update :cannot_change_content_type
  validates_attachment_size :file, :less_than => 200.megabytes
  validates_attachment_presence :file

  # ORDERING/PAGINATION                  
  order_by "created_at DESC"
  cattr_accessor :per_page
  @@per_page = 50

  # SEARCH  
  define_index do
     set_property :delta => true
     indexes file_content_type, file_file_name, title, description, credit, long_description, class_name
  end
   
  # backwards compatibility
  # TODO: remove after testing complete
  alias_attribute :content_type, :file_content_type
  alias_attribute :filename, :file_file_name
  alias_attribute :size, :file_file_size
  
  def public_filename(style='original')
    file.url(style)
  end
  
  def after_initialize
    if new_record? and type = Asset.send(:subclasses).detect { |klass| klass.file_types.include?(file_content_type) }
      self.class_name = type.name
    end
  end

  # BEGIN CLASS METHODS
  class << self
    
    def find_all_by_index(first_letter = "", page = 1)
      if first_letter =~ /^[^a-z]$/i
        conditions = "LOWER(file_file_name) REGEXP('^[^a-z]')"
      elsif first_letter =~ /^[a-z]$/i
        conditions = ["LOWER(file_file_name) LIKE ?", "#{first_letter.downcase}%"]
      else
        conditions = nil
      end
      paginate :conditions => conditions, :page => page, :order => 'file_file_name'
    end
    
    def find_expired(page = 1)
      paginate :conditions => ["expires_on IS NOT NULL AND expires_on <= ?", EXPIRATION_LOOKAHEAD.from_now.to_s(:db)], :page => page, :order => 'expires_on'
    end
    
    def find_by_path(path)
      # Pull out the id from the path
      id = path.split('/').select {|d| d =~ /^\d+$/ }.join.to_i
      find(id)
    end
  end
  # END CLASS METHODS
  
  def page_uses
    parts = PagePart.find(:all, :conditions => ["content like ?","%#{self.file_file_name}%"])
    parts.empty? ? [] : Page.find(parts.collect(&:page_id))
  end
  
  def cae_uses
    returning [] do |results|
      results << Article.find(:all, :conditions => ["image_id = ?",self.id])
      results << Article.find(:all, :conditions => ["full_text like ?","%#{self.file_file_name}%"])
    end.flatten.uniq
  end
  
  def all_uses
    self.page_uses + self.cae_uses
  end
  
  def used_in
    returning Hash.new do |results|
      page_uses.each do |e|
        (results[e.class.name] ||= []) << e
      end
      cae_uses.each do |e|
        (results["article"] ||= []) << e
      end
    end
  end

  def expired?
    self.expires_on && self.expires_on <= Date.today
  end

  def expiring_soon?
    self.expires_on && self.expires_on <= EXPIRATION_LOOKAHEAD.from_now.to_date
  end
  
  # reset some attrs when replacing file with new upload
  def file_with_replacement=(uploaded_file)
    self.file_without_replacement = uploaded_file
    self.file_content_type = File.mime_type?(self.filename)
    self.created_at = :utc == ActiveRecord::Base.default_timezone ? Time.now.utc : Time.now.localtime
    self.file_file_name = original_file_file_name if not new_record?
  end
  alias_method_chain :file=, :replacement
  
  def width
    @geometry ||= Paperclip::Geometry.from_file(self.file)
    @geometry.width.to_i
  rescue
    0
  end
  
  def height
    @geometry ||= Paperclip::Geometry.from_file(self.file)
    @geometry.height.to_i
  rescue
    0
  end
  
  def dimensions
    "#{width} x #{height}"
  end
  
  def to_zip
    # clone some extra attributes
    zip_asset = self.becomes(ZipAsset)
    zip_asset.unzip = self.unzip
    zip_asset.file = self.file
    zip_asset
  end
  
  private
    def cannot_change_content_type
      errors.add :file_content_type, "must be the same as the original file when replacing" if file_content_type_modified?
    end
    
    def before_validation
      # if self.content_type == 'application/octet-stream' || self.content_type.blank?
      #   self.content_type = File.mime_type?(self.filename)
      # end

      # we always want the mime type detected via mimetype-fu
      logger.info "before_validation: self.content_type = #{self.content_type}"
      self.content_type = File.mime_type?(self.filename)
    end
    
end