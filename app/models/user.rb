require 'rubygems'
require 'net/ldap'
require 'digest/sha1'
class User < ActiveRecord::Base
attr_accessor :password, :password_confirmation, :old_password
 attr_accessible :first_name, :last_name, :email,  :username, :password, :password_confirmation, :old_password, :user_type
validates_uniqueness_of   :username
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 8..20, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_format_of       :password, :with => /^(?=.*\d)(?=.*([a-z]|[A-Z]))([\x20-\x7E]){8,20}$/, :message => "must contain one alphabet and one numeric."

scope :search, lambda{|q| q.blank? ? {} : {:conditions => ['first_name LIKE ? or username LIKE ?', "%#{q}%", "%#{q}%"]} }
scope :search_not_super, lambda{|q| q.blank? ? {} : {:conditions => ['(first_name LIKE ? or username LIKE ?) and user_type <> ?', "%#{q}%", "%#{q}%", 4]} }
default_scope :order => 'user_type'

before_save :encrypt_password
 

  READONLY = 0
  ADMIN = 1
  SUPPORT = 2
  ANONYMOUS = 3
  SUPERADMIN = 4  
 



  def super_admin?
     self.user_type == SUPERADMIN
  end

 def admin?
    self.user_type == ADMIN
  end

  def user_readonly?
    self.user_type == READONLY
  end

  def support?
    self.user_type == SUPPORT
  end

  def anonymous?
    self.user_type == ANONYMOUS
  end

   # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(username,password)
 ldap_para = YAML::load_file("#{Rails.root}/config/ldap_parameter.yml")
    u = find(:first, :conditions => ['username = ?', username]) # need to get the salt
    if !u.nil? and ldap_para
        if  ldap_para["login_auth"] == 1 && u.user_type != 4
                u && u.ldap_authentication(username,password) ? u : nil
        else
u && u.authenticated?(password) ? u : nil
        end
    else
        return nil
    end
  end
 def self.ldap_bind_search(user)
        ldap_para = YAML::load_file("#{Rails.root}/config/ldap_parameter.yml")
                if ldap_para
                        ldap = Net::LDAP.new :host => ldap_para["ad_host"],:port => ldap_para["ad_port"],:auth => {:method => :simple,:username => ldap_para["ad_username"],:password => ldap_para["ad_password"]}
                        array = Array.new
                        if ldap.bind
                                filter1 = Net::LDAP::Filter.eq("cn",user)
                                filter2 = Net::LDAP::Filter.eq("ObjectClass" ,'Person')
                                treebase= ldap_para["ad_treebase"]
                                attrs= ["cn","mail","givenname","sn","title"]
                                ldap.search(:base => treebase,:filter => filter1 & filter2,:attribute => attrs)do |entry|
                                        array << "#{entry.cn}"
                                        array << "#{entry.mail}"
                                        array << "#{entry.givenname}"
                                        array << "#{entry.sn}"
                                        dn = String.new
                                        strcn=String.new
                                        dn = entry.manager.to_s
                                        strcn = dn.split(',')
                                        cn = strcn[0].split('=')
                                        mcn = cn[1]
                                        array << "#{mcn}"
                                        array << "#{entry.title}"
                                return array
                                  end

                         else
                            return nil
                         end
                else
                  return nil

                end
end

def self.sample_ldap_search(host,port,sig,tree,user,pass)
begin
        ldap = Net::LDAP.new :host => host,:port => port,:auth => {:method => :simple,:username => user,:password => pass}
                        array = Array.new
                        if ldap.bind
                                filter1 = Net::LDAP::Filter.eq("cn",sig)
                                filter2 = Net::LDAP::Filter.eq("ObjectClass" ,'Person')
                                treebase= tree
                                attrs= ["cn","mail","givenname","sn","title"]
                                ldap.search(:base => treebase,:filter => filter1 & filter2,:attribute => attrs)do |entry|
                                        array << "#{entry.cn}"
                                        array << "#{entry.mail}"
                                        array << "#{entry.givenname}"
                                        array << "#{entry.sn}"
                                        array << "#{entry.title}"
                                        return array
                                        end
                        else
                                return false
                        end
rescue Net::LDAP::LdapError => e
       return "Exception"
rescue NoMethodError  => e
        return "Exception"
end
end

  def ldap_authentication(user,pwd)
    ldap_para = YAML::load_file("#{Rails.root}/config/ldap_parameter.yml")
    if ldap_para
      treebase =  "#{ldap_para["ad_treebase"]}"
      ldap = Net::LDAP.new :host => ldap_para["ad_host"],:port => ldap_para["ad_port"],:auth => {:method => :simple,:username =>ldap_para["ad_username"],:password => ldap_para["ad_password"]}
      result = ldap.bind_as(:base => treebase ,:filter => "(cn = #{user})",:password =>pwd)
      if result
        if ldap.bind
          return true
        else
          return false
        end
      else
        return false
      end
    else
      return false
    end
  end

def self.authentication_type?
    ldap_para = YAML::load_file("#{Rails.root}/config/ldap_parameter.yml")
    if ldap_para
      if ldap_para["login_auth"] == 0
        return true
      else
        return false
      end
    else
      return false
    end
  end

 def full_name
    first_name + ' ' + last_name
  end
def type_of_user
    ut= ["Read Only", "Admin", "Support", "Anonymous","Super Admin"]
    ut[self.user_type]
  end

 def self.encrypt(password,salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(:validate=> false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.is_login = 0
    self.remember_token            = nil
    save(:validate=> false)
  end


  def forgot_password
    self.update_attribute(:url_access_key, Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--"))
    UserMailer.forgot_password(self).deliver
  end

 def self.random_code(size = 10)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end


protected
    # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    (crypted_password.blank? || !password.blank?) && !anonymous?
  end
end
