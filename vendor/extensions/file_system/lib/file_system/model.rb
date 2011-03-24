module FileSystem
  module Model
    FILENAME_REGEX = /^(?:(\d+)_)?([^.]+)(?:\.([\-\w]+))?/
    CONTENT_TYPES = {"html" => "text/html", 
                     "css" => "text/css",
                     "xml" => "application/xml",
                     "rss" => "application/rss+xml",
                     "txt" => "text/plain",
                     "js" => "text/javascript",
                     "yaml" => "text/x-yaml"}
        
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def path
        File.join(RAILS_ROOT, "design", class_of_active_record_descendant(self).name.pluralize.underscore)
      end
      
      def find_or_initialize_by_filename(filename)
        id = extract_id(filename)
        name = extract_name(filename)
        find_by_id(id) || find_by_name(name) || new
      end
      
      def load_files
        Dir[path + "/**"].each do |file|
          record = find_or_initialize_by_filename(file)
          archived = record.dup.without_ignored_fields
          if record.respond_to? :requires_original
            record.requires_original = record.content
          end
          record.load_file(file)
          record.save
          unless record.without_ignored_fields.eql?(archived)
            puts "L + Loaded #{record.file_system_name} from #{File.basename(file)}."
          else
            puts "I - Ignoring #{record.file_system_name} file #{File.basename(file)}: file_system matches database." if ENV['verbose']
          end
        end
      end
      
      def save_files
        find(:all).each(&:save_file)
      end
      
      def extract_id(filename)
        basename = File.basename(filename)
        $1.to_i if basename =~ FILENAME_REGEX
      end
      
      def extract_name(filename)
        basename = File.basename(filename)
        $2 if basename =~ FILENAME_REGEX
      end
    end
    
    def load_file(file)
      name, content_type = $2, $3 if File.basename(file) =~ FILENAME_REGEX
      content = open(file).read
      self.name = name
      self.content = content
      self.content_type = CONTENT_TYPES[content_type] if respond_to?(:content_type)
    end
    
    def save_file
      FileUtils.mkdir_p(File.dirname(self.filename)) unless File.directory?(File.dirname(self.filename))
      if File.exist?(self.filename)
        oldcontent = File.open(self.filename).read
        if self.content.eql?(oldcontent) || self.content.nil?
          puts "I - Ignoring #{self.file_system_name} file for #{File.basename(filename)}: file_system matches database." if ENV['verbose']
        else
          write_file
        end
      else
        FileUtils.mkdir_p(File.dirname(self.filename))
        puts "N + Created new #{self.file_system_name} file for #{File.basename(filename)}."
        write_file
      end
    end
    
    def write_file
      File.open(self.filename, "w") { |f| f.write self.content }
      puts "M ~ Wrote #{self.file_system_name} file for #{File.basename(filename)}."
    end
    
    def filename
      @filename ||= returning String.new do |output|
        basename = self.name
        extension = respond_to?(:content_type) ? CONTENT_TYPES.invert[self.content_type] || "html" : "html"
        output << File.join(self.class.path, [basename, extension].join("."))
      end
    end
    
    def without_ignored_fields
      ignored_fields = %w{created_at updated_at created_by_id updated_by_id lock_version id}
      fields = self.attributes.delete_if { |k,v| ignored_fields.include?(k) }
      return fields.inspect
    end
  
    def file_system_name
      name = self.class.name.downcase
      case name
      when "contenttype"
        name = "content type"
      when "parttype"
        name = "part type"
      when "pickerparttype"
        name = "picker part type"
      end
      return name
    end
  end
end