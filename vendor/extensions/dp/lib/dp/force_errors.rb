module DP
  module ForceErrors

    def self.included(base)
      base.alias_method_chain :raise_errors?, :dp
    end

    def raise_errors_with_dp?
      true
    end
  end
end