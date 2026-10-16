# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes

  attribute :user
  # The ApiToken an API request was made with, if any.
  attribute :api_token
  attribute :user_key
  attribute :user_agent, :ip_address

  def user
    super || NullUser.new
  end

end
