require File.dirname(__FILE__) + '/abstract_unit'
require File.dirname(__FILE__) + '/fixtures/person'
require File.dirname(__FILE__) + '/fixtures/group'
require File.dirname(__FILE__) + '/fixtures/animal'
require File.dirname(__FILE__) + '/fixtures/album'

class ActsAsModifiedTest < Test::Unit::TestCase
  fixtures :people, :groups, :schools, :animals, :albums
  
  def test_initial_values
    p = Person.new
    assert_equal p.attributes, p.original_attributes
    assert_equal p.attributes_before_type_cast, p.original_attributes_before_type_cast
    assert_equal Hash.new, p.modified_attributes
    
    p = people(:jonathan)
    assert_equal p.attributes, p.original_attributes
    assert_equal p.attributes_before_type_cast, p.original_attributes_before_type_cast
    assert_equal Hash.new, p.modified_attributes
  end
  
  def test_new_record_not_modified
    assert Person.new.modified?
  end
  
  def test_loaded_record_not_modified
    assert !people(:jonathan).modified?
  end
  
  def test_change_attribute
    people(:jonathan).name = people(:jonathan).name
    assert !people(:jonathan).modified?
    
    people(:jonathan).name = 'Commander Keen'
    assert people(:jonathan).modified?
  end
  
  def test_restore_all_attributes
    p = people(:jonathan)
    p.attributes = { :name => 'Changed', :lucky_number => 10 }
    
    assert_equal 'Changed', p.name
    assert_equal 10, p.lucky_number
    assert p.modified?
    
    p.restore_attributes
    
    assert_equal 'Jonathan', p.name
    assert_equal 55, p.lucky_number
    assert !p.modified?
    
    assert_equal Hash.new, p.modified_attributes
    assert_equal p.attributes, p.original_attributes
  end
  
  def test_save_does_not_clear_original_attributes
    p = people(:jonathan)
    p.name = 'Changed'
    
    assert_equal({ 'name' => 'Jonathan' }, p.modified_attributes)
    assert p.modified?
    assert p.save
    assert_equal({ 'name' => 'Jonathan' }, p.modified_attributes)
    assert p.modified?
  end
  
  def test_save_clears_original_attributes
    g = groups(:rails)
    g.name = 'Java'
    
    assert_equal({ 'name' => 'Rails Group' }, g.modified_attributes)
    assert g.modified?
    assert g.save
    assert_equal({}, g.modified_attributes)
    assert !g.modified?
  end
  
  def test_modified_attribute_suffix
    p = people(:jonathan)
    
    assert !p.name_modified?
    p.name = 'Jonathan'
    assert !p.name_modified?
    assert_equal 'Jonathan', p.name
    
    p.name = 'Changed'
    assert p.name_modified?
    assert_equal 'Changed', p.name
    
    p.restore_attributes
    
    assert !p.name_modified?
    assert_equal 'Jonathan', p.name
  end
  
  def test_method_missing_original
    p = people(:jonathan)
    
    assert_equal p.name, p.original_name
    p.name = 'Changed'
    assert_equal 'Jonathan', p.original_name
  end
  
  def test_method_missing_invalid_attribute
    assert_raises(NoMethodError) { people(:jonathan).original_aaa }
  end
  
  def test_method_missing_original_association
    assert_equal people(:jonathan).school, people(:jonathan).original_school
  end
  
  def test_method_missing_original_association_missing
    people(:jonathan).school.destroy
    assert_not_nil people(:jonathan).original_school_id
    
    assert_nothing_raised do
      assert_nil people(:jonathan).original_school
    end
  end
  
  def test_reload_should_always_clear_original_attributes
    p = people(:jonathan)
    
    # The original attributes for Person are not cleared on save, no :clear_after_save.
    # Reloading should always clear the original attributes.
    assert p.update_attributes(:name => 'Changed')
    assert p.modified? # Comparing 'Jonathan' with 'Changed'
    p.reload
    assert !p.modified? # Comparing 'Changed' with 'Changed'
  end
  
  def test_default_excluded_attributes_do_not_cause_record_to_be_modified
    assert people(:jonathan).update_attributes(:updated_at => Time.now)
    assert !people(:jonathan).modified?
  end
  
  def test_extra_excluded_attributes_do_not_cause_record_to_be_modified
    people(:student).country = "Funnyland"
    assert !people(:student).modified?
  end
  
  def test_modified_compares_with_type_casted_attributes
    # Used to effectively compare @attributes with @original_attributes,
    # but assignments like the following would cause that to be invalid: 55 != "55"
    # Using type_casted attributes is safer    
    p = people(:jonathan)
    
    assert_equal "55", p.lucky_number_before_type_cast
    assert_equal 55, p.lucky_number
    
    p.lucky_number = 55
    
    assert_equal 55, p.lucky_number_before_type_cast
    assert_equal 55, p.lucky_number
    
    assert !p.modified?
  end
  
  def test_attributes_immutable
    assert_raises(TypeError) { people(:jonathan).name << ", Mr" }
    assert_raises(TypeError) { people(:jonathan).name.gsub!('J', '') }
  end
  
  def test_clear_original_attributes
    p = people(:jonathan)
    p.name = "Agent orange"
    p.lucky_number = 666
    
    assert p.modified?
    p.clear_original_attributes
    assert !p.modified?
  end
  
  def test_setting_and_accessing_frozen_date_and_date_time_as_strings
    p = people(:jonathan)
    
    p.birthdate = Date.today
    p.updated_at = Time.now
    p.updated_on = DateTime.now
    
    assert_nothing_raised do
      puts p.birthdate.to_s
      puts p.updated_at.to_s
      puts p.updated_on.to_s
    end
  end
  
  # Occurs when database has a null value and a blank string is saved off a form
  def test_attribute_changes_from_blank_to_blank_ignored
    p = people(:richard)
    
    assert_nil p.country
    p.update_attributes!(:country => "")
    assert_equal "", p.country
    
    assert !p.modified?
  end
  
  def test_access_id_method_on_class_with_nonstandard_primary_key_before_read_methods_generated
    Animal.reset_column_information
    
    assert_nothing_raised do
      assert_equal 1, Animal.find(1).id
    end
  end
  
  def test_attributes_missing_from_only_do_not_cause_record_to_be_modified
    a = albums(:mbv_loveless)
    
    assert !a.modified?
    a.rating = 5
    assert !a.modified?
  end
  
  def test_attributes_included_in_only_cause_record_to_be_modified
    a = albums(:mbv_loveless)
    
    a.title = "Crazy New Title"
    assert a.modified?
    assert_equal({ 'title' => 'Loveless' }, a.modified_attributes)
  end
  
  def test_modified_attributes_with_changed_values
    a = albums(:mj_bad)
    a.attributes = { :title => "Less Bad", :artist => "Auggie Jackson" }
    
    assert_equal({ 'title' => "Less Bad", 'artist' => "Auggie Jackson" }, a.modified_attributes(:changed))
  end
  
  def test_hash_substantial_differences
    assert_equal({ 1 => 1 }, { 1 => 1, 2 => 3 }.substantial_differences_to({ 1 => 4, 2 => 3 }))
    assert_equal({}, { 1 => 1 }.substantial_differences_to({ 1 => 1 }))
    
    assert_equal({}, { 1 => "  ", 3 => nil }.substantial_differences_to({ 1 => nil, 3 => "" }))
  end
end
