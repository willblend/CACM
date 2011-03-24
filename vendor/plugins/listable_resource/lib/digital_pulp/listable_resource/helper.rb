module DigitalPulp
  module ListableResource
    
    module Helper
      def path_for_sorted_column( column, order_param = :sort, direction_param = :direction )
        reverse = params[direction_param] == 'desc' ? 'asc' : 'desc' if params[order_param] == column.to_s
        url_for( :overwrite_params => { order_param => column, direction_param => reverse ? reverse : "desc", :_method => nil } )
        # always give it a direction param (defaults to desc) because without
        # that it takes 2 clicks to "reverse" a sort when it should only take
        # 1 click. -amlw 1/19/19
      end
    end
    
  end
end