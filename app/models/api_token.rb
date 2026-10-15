# frozen_string_literal: true

# A bearer token an admin issues for an AI account (a bot User), through
# which the AI uses the site's API as that account. Only a SHA-256 digest is
# stored: the token is shown once, when it's made (see .issue), so a lost
# one is revoked and replaced, never recovered.
#
# Scopes limit what a token may do on top of its account's roles:
#
#   read    - look at site data
#   propose - suggest changes for a person to review and make
class ApiToken < ApplicationRecord
  SCOPES = %w[ read propose ].freeze
  PREFIX = 'slt_'

  # How often last_used_at is updated, to save a write per request.
  USE_RESOLUTION = 1.minute

  belongs_to :user, optional: false
  belongs_to :created_by, class_name: 'User', optional: false

  scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true
  validate  :scopes_are_known
  validate  :user_is_an_ai_account

  # Makes a token, returning [ApiToken, the token itself].
  def self.issue!(user:, name:, scopes:, created_by:, expires_at: nil)
    token = "#{PREFIX}#{SecureRandom.base58(40)}"
    api_token = create!(user: user, name: name, scopes: Array(scopes).compact_blank.uniq,
                        created_by: created_by, expires_at: expires_at, token_digest: digest(token))
    [ api_token, token ]
  end

  # The active token +token+ is, if its account can still use it.
  def self.authenticate(token)
    return if token.blank? || !token.start_with?(PREFIX)
    api_token = active.includes(:user).find_by(token_digest: digest(token))
    api_token if api_token&.user&.bot? && !api_token.user.disabled?
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def allows?(scope)
    scopes.include?(scope.to_s)
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at.future?)
  end

  def expired?
    expires_at.present? && !expires_at.future?
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  def record_use!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < USE_RESOLUTION.ago
  end

  def to_s
    name.to_s
  end

  private

  def scopes_are_known
    errors.add(:scopes, 'must include at least one') if scopes.empty?
    unknown = scopes - SCOPES
    errors.add(:scopes, "has unknown #{unknown.to_sentence}") if unknown.any?
  end

  def user_is_an_ai_account
    errors.add(:user, 'must be an AI account') if user && !user.bot?
  end
end
