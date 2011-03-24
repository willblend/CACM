require File.dirname(__FILE__) + '/../test_helper'

class ZipAssetTest < Test::Unit::TestCase
  fixtures :assets
  
  def setup
    @zip = ZipAsset.new
    @zip.file = File.open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'testdata.zip'))
    assert @zip.save
  end
  
  def test_should_not_unzip_by_default
    assert !@zip.unzip?
  end
  
  def test_unzip=
    @zip.unzip = true
    assert @zip.unzip?
  end
  
  def test_should_extract_files
    files = []
    @zip.extract_each do |f|
      files << File.basename(f.path)
    end
    assert_equal %w(file_one.txt file_two.txt img.gif), files.sort
  end
  
  def test_should_not_unzip_if_unzip_is_false
    assert_no_difference 'Asset.count' do
      @zip.expects(:save_without_unzip)
      @zip.save
    end
  end
  
  def test_should_unzip_when_asked
    assert_difference 'Asset.count', 2 do # 3 assets in archive - 1 parent to be destroyed
      @zip.unzip = true
      @zip.save
    end
  end
  
  def test_should_remove_archive_when_unzipping
    @zip.unzip = true
    @zip.save
    assert_raises ActiveRecord::RecordNotFound do
      @zip.reload
    end
  end
  
  def test_should_capture_successes
    @zip.unzip = true
    @zip.save
    assert_equal 3, @zip.successes.size
    assert @zip.successes.all? { |a| a.is_a?(Asset) }
  end
  
  def test_should_clone_updated_by_when_unzipping
    @zip.unzip = true
    @zip.uploaded_by_id = 1
    @zip.save
    assert @zip.successes.all? { |a| a.uploaded_by_id == 1 }
  end
  
  def test_should_capture_failures
    Asset.any_instance.stubs(:save).returns(true).returns(true).returns(false)
    @zip.unzip = true
    assert !@zip.save
    assert !@zip.failures.empty?
    assert @zip.failures.all? { |a| a.is_a?(Asset) }
  end
  
end