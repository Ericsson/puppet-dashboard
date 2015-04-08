module AccountsHelper
  def super_member_type
    @member_type ||= [["Read Only", User::READONLY],["Admin", User::ADMIN],["Support", User::SUPPORT]]
  end
 def admin_member_type
    @member_type ||= [["Read Only", User::READONLY],["Support", User::SUPPORT]]
  end
end
