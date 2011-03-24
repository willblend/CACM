class AccountsController < CacmController
  radiant_layout "standard_fragment_cached"

  before_filter :reset_attempts, :only => [:new]
  before_filter :check_attempts, :only => [:edit, :update]
  before_filter :deny_attempt, :only => [:forgot]
  ssl_required :create, :verify, :complete, :edit, :update, :question
  ssl_allowed :new, :forgot, :verify_membership
  
  def new
  end
  
  def create
    # Ensure email not blank
    if params[:email].blank?
      flash[:error] = "You must enter your email address!"
      redirect_to new_account_path

    # Ensure email is valid
    elsif !(params[:email].match(DP::REGEXP::EMAIL))
      flash[:error] = "You must enter a valid email address!"
      redirect_to new_account_path

    # Email is valid, and an account was found, redirect them
    elsif @account = Oracle::WebAccount.find_all_by_email(params[:email])
      # commented out because we display a big modal window for this. -amlw
      # flash[:error] = "We found memberships for that email address!"
      render :template => 'accounts/new'

    # If they said they were a member and no client is found, warn them
    elsif params[:member] && params[:member].eql?("true") && !Oracle::Client.find_by_email(params[:email])
      @error_no_acm_member_found = true
      render :template => 'accounts/new'
      
    # No web account found, send off that email
    else
      @token = AccountToken.create(:email => params[:email])
      AccountNotifier.deliver_web_account_email!(@token)
    end
  end

  def verify
    if @token = AccountToken.find_by_token(params[:t])
      @account = Oracle::WebAccount.new(:email => @token.email)
      
      # Check for a client, and if one is found associate it
      if @client = Oracle::Client.find_by_email(@token.email)
        @account.client = @client.id
      end
      
      render :template => 'accounts/finish'
    else
      render :template => 'accounts/expired', :status => 410
    end
  end
  
  def complete
    if params[:oracle_web_account] && @token = AccountToken.find_by_token(params[:oracle_web_account][:token]) rescue false # In case someone fakes a form I don't want to get nil.[] errors
      
      @account = Oracle::WebAccount.new(params[:oracle_web_account].merge(:email => @token.email))

      # Associate the username if there is a client
      if @client = Oracle::Client.find_by_email(@token.email)
        @account.client = @client.id
      end

      if @account.save
        AccountNotifier.deliver_new_account_email!(:email => @token.email, :username => @account.username, :password => params[:oracle_web_account][:password])
        @token.destroy
        params[:username] = @account.username
      else
        flash.now[:error] = "There was a problem saving your account."
        render :template => 'accounts/finish'
      end
    else
      render :template => 'accounts/expired', :status => 410
    end
  end
  
  def forgot
  end

  def question
    unless @account = Oracle::WebAccount.find_by_username(params[:username])
      flash.now[:error] = "We're sorry, we couldn't find that account. Please check your username and try again."
      render :action => 'forgot' and return
    end
  end

  def edit
    @account = Oracle::WebAccount.find_by_username(params[:username])
    if @account.answer(params[:answer])
      render :template => 'accounts/reset'
    else
      increment_attempts
      flash.now[:error] = "That answer is incorrect. Please try again."
      render :template => 'accounts/question'
    end
  end
  
  def update
    @account = Oracle::WebAccount.find_by_username(params[:username])

    if params[:password] && params[:password_confirm] && params[:password].eql?(params[:password_confirm])
      @account.answer = params[:answer]
      @account.password = params[:password]
      if @account.update_password
        flash[:notice] = "Your password has been reset, please login!"
        redirect_to member_login_path
      else
        errors = @account.errors.map{|x| "#{x[0]} : #{x[1]}"}.join("<br />")
        flash.now[:error] = "There was a problem updating your password. <br /> #{errors}"
        render :template => 'accounts/reset'
      end
    else
      flash.now[:error] = "Your password and confirmation both are required and must match!"
      render :template => 'accounts/reset'
    end
  end
  
  def verify_membership
    respond_to do |format|
      format.html { redirect_to "/" }
      format.js do
        render :text => '' and return if not params[:email].blank?
        if @account = Oracle::WebAccount.find_all_by_email(params[:email])
          render :partial => 'accounts/modal'
        elsif @account = [Oracle::Client.find_by_email(params[:email])]
          render :partial => 'accounts/modal'
        else
          render :text => ''
        end
      end
    end
  end

  private
    def reset_attempts
      session[:attempts] = 0
      session[:attempts_maxed_at] = nil
    end
    
    def increment_attempts
      session[:attempts] +=1
    end
    
    def deny_attempt
      if session[:attempts] && session[:attempts_maxed_at]
        if (session[:attempts_maxed_at]+5.minutes) > Time.now
          redirect_to_signup_and_notify
        end
      end
    end
  
    def check_attempts
      if session[:attempts] && session[:attempts] >= 3
        session[:attempts_maxed_at] = Time.now
        redirect_to_signup_and_notify
      elsif !session[:attempts]
        reset_attempts
        true
      end
    end
    
    def redirect_to_signup_and_notify
      flash[:warning] = "You have exceeded the number of answers attempts allowed for your security question and will have to wait five minutes before attempting once more.<br /><br />Please create a web account or contact ACM by emailing cacm-admin@cacm.acm.org to retrieve your account information"
      redirect_to member_login_path
    end

end