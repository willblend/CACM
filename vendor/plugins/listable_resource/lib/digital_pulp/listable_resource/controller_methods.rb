module DigitalPulp  
  module ListableResource
    module ControllerMethods
      
      def self.included(base)
        base.extend ClassMethods
      end
    
      module ClassMethods
        def listable_resource(model, opts={})
          # most of these vars could be localized, but they're
          # left as instances to make testing a little easier
          model = model.to_s.camelcase.constantize
          raise DigitalPulp::ListableResource::ListableResourceError, "#{model} is not a listable resource" unless model.included_modules.include?(DigitalPulp::ListableResource::InstanceMethods)
      
          sort_fields = (sorts = opts.delete(:sorts)) ? [*sorts] : model.sortable_fields          
          default_sort = (default = opts.delete(:default)) ? default : sort_fields.first

          sortproc = lambda do |params|
            sort = sort_fields.include?(params[:sort]) ? params[:sort] : default_sort
            direction = ('desc' == params[:direction]) ? 'desc' : 'asc'
            "#{sort} #{direction}"
          end

          define_method :order_and_direction do
            sortproc.call(params)
          end
        end
      end
    
    end
  end
end