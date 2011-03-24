class ImageAsset < Asset
  # CACM-specific
  has_many :articles, :dependent => :nullify, :foreign_key => :image_id

  self.file_types = %w{image/jpeg image/pjpeg image/gif image/png image/x-png image/jpg}
end