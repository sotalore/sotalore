# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes

  attribute :current_user_id
  attribute :user_key
  attribute :user_agent, :ip_address

  resets do
    @user = nil
  end

  def user
    @user ||= User.find_by(id: current_user_id) || NullUser.new
  end

  def user=(user)
    @user = user || NullUser.new
    if @user.null?
      self.current_user_id = nil
    else
      self.current_user_id = @user.id
    end
    user
  end

end
