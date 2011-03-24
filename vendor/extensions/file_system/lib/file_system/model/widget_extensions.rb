require "xml/libxml"
require "libxml"

module FileSystem::Model::WidgetExtensions
  def self.included(base)   
    # Instance methods
    base.class_eval do
      before_save :copy_attributes_from_db
      attr_accessor :requires_original
    end
    
    def copy_attributes_from_db
      # so now in this callback we have the new content in place and the original content in requires_original
      if requires_original
        begin
          # parse the new markup
          new_widget = LibXML::XML::Parser.string("<widget xmlns:r=\"http://www.r.com/r/1.0/\">"+content.fck_cleanup+"</widget>").parse

          # parse the old markup
          old_widget = LibXML::XML::Parser.string("<widget xmlns:r=\"http://www.r.com/r/1.0/\">"+requires_original.fck_cleanup+"</widget>").parse

          old_widget.find('//r:*').each_with_index do |rtag,index|
            # now get this tags attributes
            rtag.attributes.each do |attribute|
              new_widget.find('//r:*')[index].attributes[attribute.name] = rtag[attribute.name]
            end
          end

          forAR = new_widget.root.child.to_s.gsub(/ xmlns:r=\"http:\/\/www.r.com\/r\/1.0\/\"/,'')
          self.content = forAR
          puts "Saved #{self.name} Successfully"
        rescue Exception => e
          puts "Failed to Save #{self.name} -- #{e}"
          self.errors.add_to_base "Failed to Save"
          false
        ensure
          new_widget = nil ; GC.start
        end
      end
    end
    
  end
end