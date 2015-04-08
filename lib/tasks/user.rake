namespace :user do
  desc "Add Super Admin User"
  task :create_super_admin_user => :environment do
   first_name = SETTINGS.super_admin_first_name
    last_name = SETTINGS.super_admin_last_name
    user_type = SETTINGS.super_admin_user_type
    email =  SETTINGS.super_admin_email
    username = SETTINGS.super_admin_username
    password = SETTINGS.super_admin_password
    password_confirmation = SETTINGS.super_admin_password_confirmation
    user = User.find_by_email(email)
    unless user
      begin
        super_admin = User.new(:first_name => first_name, :last_name => last_name, :username => username, :email => email, :password => password, :password_confirmation => password_confirmation)
        super_admin.user_type = user_type
        super_admin.save!
        puts 'Super Admin user successfully created!'
      rescue => e
        puts "There was a problem creating the user: #{e.message}"
        exit 1
      end
    else
     puts "Super Admin User adready exists."
    end

  end

end
