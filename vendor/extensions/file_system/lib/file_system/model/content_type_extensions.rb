require 'yaml'
module FileSystem::Model::ContentTypeExtensions
  
  FILENAME_REGEX = /^(?:(\d+)_)?([^.]+)(?:\.([\-\w]+))?/
  CONTENT_TYPE_ATTRIBUTES = ["page_class_name"]
  
  def self.included(base)
    class << base
      def load_files
        Dir[self.path + "/*.yaml", self.path + "/*.yml"].each do |yml|
          content_type = find_or_initialize_by_filename(yml)
          basename = yml.sub(/\.ya?ml/, "")
          content = Dir[basename + "*"].reject {|f| f =~ /\.ya?ml/ }.find {|f| f =~ /#{basename}(\.|$)/ }
          if content
            content_type.load_content_type_metadata(yml)
            content_type.load_content_type_content(content)
            content_type.save
          end
        end
      end
      def save_files
        find(:all).each do |ct|
          ct.save_content_type_metadata
          ct.save_content_type_content
        end
      end
    end
  end
  
  def load_content_type_metadata(filename)
    if yml = YAML::load_file(filename)
      self.name = File.basename(filename).sub(/\.ya?ml/,"")
      self.layout_name = yml.delete('layout_name')
      CONTENT_TYPE_ATTRIBUTES.each { |a| self.update_attribute(a, yml.delete(a)) }
      self.content_type_parts = yml
      puts "L + Loaded content type file #{File.basename(filename)}."
    end
  end
  
  def load_content_type_content(filename)
    self.name = $2 if File.basename(filename) =~ FILENAME_REGEX
    unless self.content.eql?(open(filename).read)
      self.content = open(filename).read
      puts "L + Loaded content type file #{File.basename(filename)}."
    else
      puts "I - Ignoring content type file #{File.basename(filename)}: file_system matches database." if ENV['verbose']
    end
  end
  
  def save_content_type_metadata
    @hash = self.content_type_parts.inject({}) do |h,part|
      h.merge(part.id => { 
        'filter_id' => part.filter_id, 
        'name' => part.name,
        'part_type_name' => part.part_type ? part.part_type.name : nil,
        'description' => part.description
      })
    end
    CONTENT_TYPE_ATTRIBUTES.each { |a| @hash[a] = self[a] rescue "" }
    @hash['layout_name'] = self.layout.name rescue "Blank"
    @yaml_filename = self.filename.sub(/\.\w+$/, ".yaml")
    if File.exist?(@yaml_filename)
      unless File.read(@yaml_filename).eql?(YAML.dump(@hash))
        write_content_type_parts_file
      else
        puts "I - Ignoring content type file #{File.basename(@yaml_filename)}: file_system matches database." if ENV['verbose']
      end
    else
      create_new_content_type_file(@yaml_filename)
      write_content_type_parts_file
    end
  end
  
  def save_content_type_content
    content = self.content
    if File.directory?(File.dirname(self.filename))
      if File.exist?(self.filename)
        if File.read(self.filename).eql?(self.content)
          puts "I - Ignoring content type file #{File.basename(self.filename)}: file_system matches database." if ENV['verbose']
        else
          write_content_type_content_file
        end
      else
        create_new_content_type_file(self.filename)
        write_content_type_content_file
      end
    else
      create_new_content_type_file(self.filename)
      write_content_type_content_file
    end
  end
  
  def create_new_content_type_file(file)
    FileUtils.mkdir_p(File.dirname(file))
    puts "N + Created new content type file for #{File.basename(file)}."
  end
  
  def write_content_type_content_file
    File.open(self.filename, 'w') { |f| f.write self.content }
    puts "M ~ Wrote content type file #{File.basename(self.filename)}."
  end
  
  def write_content_type_parts_file
    File.open(@yaml_filename, 'w') { |f| f.write YAML.dump(@hash) }
    puts "M ~ Wrote content type file #{File.basename(@yaml_filename)}."
  end
  
  def layout_name=(name)
    self.layout = Layout.find_by_name(name) || Layout.find_by_name("Blank")
  end
  
end