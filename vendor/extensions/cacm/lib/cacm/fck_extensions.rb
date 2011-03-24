module CACM
  module FCKExtensions
    
    # When this module is included on a Model, it gets a before_save hook
    # to `run_fck_cleanup`, which runs the Model.content through fck_cleanup,
    # which is a big gsubbing method designed to strip out FCK's often
    # clunky markup handling. 
    
    # The fck_cleanup method is defined in lib/cacm/string_extensions.rb
    
    # The models to include this on are defined in cacm_extension.rb.
    # As of 3/3/2009, this is included on:
    # -- PagePart
    # -- Snippet
    
    def self.included(base)
      base.class_eval do
        before_save :run_fck_cleanup
      end
    end
    
    private
      
      def run_fck_cleanup
        self.content = self.content.fck_cleanup
      end

  end
end