module Admin::UserHelper
  def roles(user)
    user.roles.map(&:name).join(', ')
  end
end