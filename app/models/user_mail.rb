require 'net/smtp'
require 'rubygems'
require 'net/ldap'
require 'yaml'

class UserMail< ActiveRecord::Base


#######To send mail to individual using smtp
def self.send_mail(send_email,msg,name)
message = <<MESSAGE_END
From: <noreply@domain.com>
To: <#{send_email}>
MIME-Version: 1.0
Content-type: text/html
Subject: Notification From Puppet

<font color="#336699" size="3"><b>Puppet Dashboard</b></font><br/><br/>
<font size='2'>This e-mail is for information only. Please do not respond to it.<br/>
<hr/>
<p>
Hello #{name.upcase},<br/><br/> 
#{msg}<br/>
<br/><br/>
<b>Disclaimer:</b>The information contained in this e-mail and any accompanying documents may contain information that is confidential or otherwise protected from disclosure. If you are not the intended recipient of this message, or if this message has been addressed to you in error, then delete this message.
</p>
</font>      

MESSAGE_END

Net::SMTP.start(SETTINGS.smtp_host_ip,25) do |smtp|
  smtp.send_message message, 'noreply@domain.com',
                             send_email
end

return true
end


def self.change_access_mail(name,email,pre_type,new_type)
	msg = "Your access on Puppet-Dashboard has been changed from #{pre_type} to #{new_type}."
	send_mail(email,msg,name)
end

def self.add_user_mail(mail,name,type,pass)
        msg = "Your account has been created on Puppet-Dashboard with #{type} access. Now you can login by your LDAP credentials but in case your LDAP credentials does not work, then your alternate password is #{pass}."
        UserMail.send_mail(mail,msg,name)
end

def self.delete_user_mail(name,email)
	msg = "Your account on Puppet-Dashboard has been deleted."
        UserMail.send_mail(email,msg,name)
end

def self.reset_pwd_mail(pwd,name,email)
	msg = "Your alternate password of Puppet-Dashboard has been changed. Now your new password is '#{pwd}'."
	UserMail.send_mail(email,msg,name)

end
end
