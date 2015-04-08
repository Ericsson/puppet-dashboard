class AccountsController < ApplicationController
#skip_before_filter :login_required, :except => [:edit, :update]
#  filter_parameter_logging :pass
skip_before_filter :verify_authenticity_token
  before_filter :admin_required, :except => [:reset_password, :update_password]

########To display all users and their information
def index
  @val = User.authentication_type?
  if request.format == "csv"
    if params[:user]
      if current_user.user_type == 4
        @users = User.search(params[:user]) if params[:user]
      else
        @users = User.search_not_super(params[:user]) if params[:user]
      end
    else
      if current_user.user_type != 4
        @users = User.all(:conditions =>["user_type <> ?",4] )
      else
        @users = User.all
      end
    end
  else
    if current_user.user_type != 4
      @users = paginate_scope User.all(:conditions =>["user_type <> ?",4] )
    else
      @users = paginate_scope User.all
    end
  end
end

def search
 if current_user.user_type == 4
    @users = paginate_scope User.search(params[:user]) if params[:user]
else
 @users = paginate_scope User.search_not_super(params[:user]) if params[:user]
end
        render :action => 'index'

end
#######To display interface for creation of account of any user
def new
    @user = User.new(params[:user])
end


########To create account of user
def create
 begin
        if params[:user][:username] == ""
                 flash[:notice] = "Username cannot be blank."
                 redirect_to new_account_path

        else
                user = Array.new
                user = User.ldap_bind_search(params[:user][:username])
                if user.blank?
                        params[:notice] = "Username is not valid."

                        flash[:notice] = "Username is not valid."
                        redirect_to new_account_path
                else
  @user = User.new(params[:user])
                        @user.user_type = params[:user][:user_type].to_i
                        @user.username = params[:user][:username]
                        @user.email =  user[1][2..-3]#user[1]
                        @user.first_name =  user[2][2..-3]#user[2]
                        @user.last_name =  user[3][2..-3]#user[3]
                        @user.password = User.random_code << '12'
                        @user.password_confirmation = @user.password
                        if @user.save!
                                UserMail.add_user_mail(@user.email,@user.first_name,@user.type_of_user,@user.password)
                                flash[:notice] = "User is added successfully."
                                redirect_to accounts_path

                        else
                                flash[:notice] = "User is not added."
                                redirect_to new_account_path

                        end
                end
        end
 rescue ActiveRecord::RecordInvalid
    render :action => 'new'
 rescue ActiveRecord::StatementInvalid => error
    raise error unless error.to_s =~ /Mysql::Error: Duplicate/

    @user.errors.add_to_base("Username has already been taken")
    params[:notice] = "Username has already been taken"
    render :action => 'new'
 rescue Net::LDAP::LdapError => e
                Filewrite.write_app_log("Exception::#{e}")
                flash[:error] = "Unable to connect to LDAP server."
                params[:notice] = "Unable to connect to LDAP server."
                redirect_to new_account_path
  rescue Net::SMTPError => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "User is added successfully but error in sending mail to this user."
 params[:notice] = "User is added successfully but error in sending mail to this user."
                 redirect_to accounts_path
 rescue Exception => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "Some problem occured, try again."
                 params[:notice] = "Some problem occured, try again."
                 redirect_to new_account_path
end

end

######To display interface to change access of any user
def edit
    @user = User.find(params[:id])
    if @user.super_admin?
      redirect_to accounts_path
    end
end

#######To change access of user
def update
    @user = User.find(params[:id])
    unless @user.super_admin?
     begin
        if @user.user_type.to_s == params[:user][:user_type]
                flash[:notice] = "This user already has #{@user.type_of_user} access"
                redirect_to accounts_path
        else
                previous_type = @user.type_of_user
                @user.update_attribute(:user_type, params[:user][:user_type]) if params[:user][:user_type]
                UserMail.change_access_mail(@user.first_name, @user.email,previous_type,@user.type_of_user)
                flash[:notice] = 'This user access is successfully changed'
                redirect_to accounts_path
        end
      rescue ActiveRecord::RecordInvalid
                 render :action => 'edit'
rescue Net::SMTPError => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "This user access is successfully changed but error in sending mail to this user."
                 redirect_to accounts_path
      rescue Exception => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "Some problem occured,try again."
                 redirect_to accounts_path
      end


    else
      redirect_to accounts_path
    end
end

#######To display interface for changing passsword to user 
def reset_password
    @user = User.find(params[:id])
     if @user != current_user
      redirect_to '/'
    end
  end

#######To change password according to user 
def update_password
    @user = User.find(params[:id])
      unless @user != current_user
      @old_password = params[:user][:old_password]
      @new_password = params[:user][:password]
      u = User.authenticate(@user.username, @old_password)
      u2 = User.authenticate(@user.username, @new_password)
      if !u2
        if u
          begin
            @user.update_attributes!(params[:user])
 @user.update_attribute(:user_type, params[:user][:user_type]) if params[:user][:user_type]
            flash[:notice] = 'Successfully Changed'
            redirect_to '/'
          rescue ActiveRecord::RecordInvalid
                render :action => 'reset_password'
          rescue Exception => e
                Filewrite.write_app_log("Exception::#{e}")
                flash[:notice] = "Some problem occured,try again."
                redirect_to reset_password_account_path
          end

        else
          flash[:password_error] = "Old Password didnot match."
          redirect_to reset_password_account_path
        end
      else
        flash[:password_error] = "New password can not be same as old password"
        redirect_to reset_password_account_path
      end
    else
      redirect_to '/'
    end
  end


#########To reset password of any user  
def reset_password_automatically
  @user = User.find(params[:id])
  unless @user.super_admin?
  begin
        pwd = String.new
        pwd = User.random_code << '12'
        @user.password = pwd
        @user.password_confirmation = pwd
        @user.save
        UserMail.reset_pwd_mail(pwd,@user.first_name,@user.email)
 flash[:notice] = 'This user password is successfully changed.'
        redirect_to accounts_path
      rescue Net::SMTPError => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "This user password is successfully changed but error in sending mail to this user."
                 redirect_to accounts_path
      rescue Exception => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "Some problem occured,try again."
                 redirect_to accounts_path
      end

  end
end


#########To delete any user
def destroy
begin
    @user = User.find(params[:id])
    unless @user.super_admin?
     name = @user.first_name
     email = @user.email
     @user.destroy
     flash[:notice] = 'This user is successfully deleted'
     UserMail.delete_user_mail(name,email)
    end
    redirect_to accounts_path
rescue Net::SMTPError => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "This user is successfully deleted but error in sending mail to this user."
                 redirect_to accounts_path
rescue Exception => e
                Filewrite.write_app_log("Exception::#{e}")
                 flash[:notice] = "Some problem occured,try again."
                 redirect_to accounts_path
end

end

end
