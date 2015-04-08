class SessionsController < ApplicationController
skip_before_filter :login_required, :session_expiry, :update_session
skip_before_filter :verify_authenticity_token
  def new
    redirect_to "/" if current_user
  end

  def create
 begin
    if (params[:username] == "" or  params[:password] == "" )
      flash.now[:error] = "Fields cannot be blank."
      render :action => 'new' 
    else
    u = User.authenticate(params[:username], params[:password])
    if u
      if u.is_login
        flash.now[:notice] = 'User already logged in or relogin after 10 minutes.'
        render :action => 'new'
 
     else
      self.current_user = u

        if logged_in?
           u.update_attribute(:is_login,true)
           s = Session.find_by_session_id(request.session_options[:id])
           unless s.nil?
             s.update_attribute(:user_id , u.id)
           end
          if params[:remember_me] == "1"
            self.current_user.remember_me
            cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          end
          if current_user
              redirect_back_or_default('/')
          end
        end
      end
    else
      flash.now[:error] = 'Invalid username or password'
      render :action => 'new'
    end
  end
  rescue Net::LDAP::LdapError => e
                Filewrite.write_app_log("Exception::#{e}")
                flash[:error] = "Unable to connect to LDAP server."
                redirect_to new_session_path
  end
  end
 def destroy
    self.current_user.forget_me if logged_in?
    reset_session
    flash[:notice] = 'You have been logged out'
    redirect_to '/'
  end

 
 end
