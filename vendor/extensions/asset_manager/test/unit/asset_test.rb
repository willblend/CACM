require File.dirname(__FILE__) + '/../test_helper'

class AssetTest < Test::Unit::TestCase
  fixtures :assets, :pages, :page_parts
  
  def setup
    @asset = Asset.new
  end

  def test_find_expired
    @expired = Asset.find_expired
    assert_included @expired, assets(:expired)
    assert_not_included @expired, assets(:png)
    assert_not_included @expired, assets(:qt)
  end

  def test_find_all_by_index
    assert_equal [assets(:png)], Asset.find_all_by_index('m')
    assert_equal [assets(:qt)], Asset.find_all_by_index('v')
    assert_equal [assets(:expired)], Asset.find_all_by_index('a')
    (("a".."z").to_a - ['a', 'm', 'v'] + ["#"]).each do |letter|
      assert_equal [], Asset.find_all_by_index(letter)
    end
    assert_equal Asset.find(:all, :order => 'file_file_name'), Asset.find_all_by_index
  end

  def test_should_be_flash_when_content_type_is_flash
    @asset.content_type = "application/x-shockwave-flash"
    assert @asset.flash?
  end
  
  def test_should_be_video_when_content_type_is_video
    @asset.content_type = "video/quicktime"
    assert @asset.video?
    
    @asset.content_type = "video/mpeg"
    assert @asset.video?
  end
  
  def test_should_be_image_when_content_type_is_image
    @asset.content_type = "image/png"
    assert @asset.image?
    
    @asset.content_type = "image/tiff"
    assert @asset.image?
  end
  
  def test_should_be_audio_when_content_type_is_audio
    @asset.content_type = "audio/wav"
    assert @asset.audio?
    
    @asset.content_type = "audio/mpeg"
    assert @asset.audio?
  end

  def test_uses_should_return_pages_that_contain_the_asset
    asset = assets(:png)
    Page.expects(:search).with(asset.file.path)
    asset.page_uses
  end
  
  def test_used_in_should_partition_by_class
    page = Page.new
    Page.stubs(:search).returns([page])
    asset = assets(:png)
    assert_equal({'Page' => [page]}, asset.used_in)
  end
  
  def test_find_by_path
    assert_equal assets(:png), Asset.find_by_path("/system/assets/files/0000/0001/mypng.png")
  end
  
  def test_should_not_rename_when_uploading_new_file_to_existing_asset
    asset = assets(:png)
    asset.file = file_upload('book.png', 'image/png')
    assert_equal 'mypng.png', asset.filename
  end
  
  def test_should_change_created_at_when_uploading_new_file_to_existing_asset
    asset = assets(:png)
    old_created_at = asset.created_at
    asset.file = file_upload('book.png', 'image/png')
    assert_not_equal old_created_at, asset.created_at
  end
  
  def test_should_require_new_file_to_be_same_content_type
    asset = assets(:png)
    asset.file = file_upload('assets.yml', 'text/x-yaml')
    
    assert !asset.valid?
    assert_not_nil asset.errors.on(:file_content_type)
  end
  
  def test_should_accept_bad_filetypes_if_file_is_actually_ok
    asset = assets(:png)
    asset.file = file_upload('book.png', 'application/octet-stream')
    assert asset.valid?
  end
  
  def test_should_create_asset_from_filesystem
    asset = Asset.new(:file => File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'book.png')))
    assert asset.valid?
  end
    
  def test_correctly_reports_file_type
    asset = Asset.new(:file => File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'book.png')))
    assert_equal 'image/png', asset.content_type
  end
  
  def test_new_should_add_class_name_attr
    assert_equal 'ImageAsset', Asset.new(:content_type => 'image/png').class_name
  end
  
  def test_should_validate_file_type
    asset = ImageAsset.new
    asset.file_content_type = 'audio/mpeg'
    assert !asset.valid?
    assert_equal 'File type is not accepted', asset.errors.on(:file_content_type)
  end
  
  def test_should_coerce_to_zip
    file = File.open(File.join %w(.. fixtures testdata.zip))
    asset = Asset.new(:file => file)
    asset.unzip = 'foo'
    z = asset.to_zip
    assert_equal asset.file_file_name, z.file_file_name
    assert_equal 'foo', z.unzip
  end
end
