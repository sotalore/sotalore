# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes

  attribute :user
  attribute :user_key
  attribute :user_agent, :ip_address

end
