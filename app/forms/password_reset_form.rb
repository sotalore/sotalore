# frozen_string_literal: true

class PasswordResetForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include PasswordValidation

  attribute :password, :string
  attribute :password_confirmation, :string

  def initialize(user, attrs={})
    @user = user
    super(attrs)
  end

  def save(attrs={})
    assign_attributes(attrs)
    return false unless valid?
    @user.update!(password: password)
  end

  def persisted?
    true
  end

  private

  # THe PasswordValidation uses this, and here we can just return the password
  def password_digest
    password
  end
end