class SubscriptionsController < CacmController
  radiant_layout "standard_fragment_cached"
  
  def edit
    if current_member.indv?
      @subjects = Subject.find(:all, :order => "name ASC")
      @sections = ['News', 'Opinion', 'Blog CACM', 'Careers'].collect {|s| Section.find_by_name(s)}
      @subscription = Subscription.find_by_client_id(current_member.indv_client) || Subscription.new(:client_id => current_member.indv_client)
    else
      # not logged in; edit.html.haml will throw up a barrier page but the return address needs to be set
      # so we end up back at the preferences page after login.
      session[:return] = request.request_uri
    end
  end
  
  def update
    @subjects = Subject.find(:all)
    @sections = ['News', 'Opinion', 'Blog CACM', 'Careers'].collect {|s| Section.find_by_name(s)}
    @subscription = Subscription.find_or_create_by_client_id(current_member.indv_client)
    if @subscription.update_attributes(params[:subscription])
      flash.now[:notice] = @subscription.no_subscriptions? ? "You have been removed from all <em>Communications of the ACM</em> alerts." :
                                                             "Your email alerts preferences have been updated."
    else
      flash.now[:error] = "Please correct the errors below."
    end
    render :action => "edit"
  end
  
end