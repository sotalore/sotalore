# frozen_string_literal: true

module PasswordValidation
  extend ActiveSupport::Concern

  included do
    validate :password_present, if: :password_required?
    validates :password, length: { minimum: 8 }, allow_blank: true, if: :password_required?
    validates_confirmation_of :password, allow_blank: true, if: :password_required?
    validate :password_max_length
  end

  private

  def password_required?
    true
  end

  def password_present
    errors.add(:password, :blank) unless password_digest.present?
  end

  def password_max_length
    return unless password.present? && password.bytesize > ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED

    errors.add(:password, :too_long, count: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED)
  end


end
