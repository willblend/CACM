class SessionController < CacmController
  radiant_layout "standard_fragment_cached"

  ssl_required :create
  ssl_allowed :new
  
  def new
    session[:return] = request.referer if request.referer && request.referer.match(CACM::DOMAIN)
    # just here to trip the SSL behavior
  end
  
  def create
    if current_member.authenticate_user(params[:current_member])
      # display first/last names, but default to username if that's blank...
      flash[:notice] = "You are now logged in as <strong>#{current_member.name || current_member.username || ""}</strong>."
      redirect_to session[:return] || '/', :status => :found
      session[:return] = nil
    else
      if request.referer and request.referer !~ /login$/ # posted from elsewhere? return there
        flash[:error] = 'Incorrect username or password.'
        redirect_to :back
      else
        flash.now[:error] = 'Incorrect username or password.'
        render :action => 'new'
      end
    end
  end

  def destroy
    self.current_member = nil
    flash[:notice] = "You have been logged out."
    redirect_to member_login_path
  end

end
