# frozen-string-literal: true

class User < ApplicationRecord
  has_secure_password(validations: false)
  include PasswordValidation
  alias_attribute :password_digest, :encrypted_password

  normalizes :email, with: -> given_value { given_value.strip.downcase }

  generates_token_for :confirmation, expires_in: 2.days { email }
  generates_token_for :password_reset, expires_in: 1.hour do
    password_salt.last(10)
  end


  has_one_attached :picture

  has_many :avatars, -> { order(:id)}, dependent: :destroy, inverse_of: :user
  has_many :user_recipes, dependent: :delete_all, inverse_of: :user
  has_many :recipes, through: :user_recipes
  has_many :plantings, inverse_of: :user, dependent: :delete_all
  has_many :market_prices, inverse_of: :user, dependent: :delete_all
  has_many :api_tokens, -> { newest_first }, dependent: :delete_all, inverse_of: :user

  # root      - runs the site: the admin pages, users, imports
  # editor    - edits game data: items, recipes, groups
  # moderator - looks after comments
  ROLES = %w[ root editor moderator ]

  # AI accounts have this domain; nobody receives mail there.
  AI_EMAIL_DOMAIN = 'ai.sotalore.invalid'

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :ai_accounts, -> { where(bot: true) }
  scope :people, -> { where(bot: false) }

  before_validation :nilify_blanks

  validates :name, presence: true
  validates :name, length: { in: 3..64 }
  validates :name, uniqueness: { ignore_case: true }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate  :ai_accounts_have_no_password

  def self.from_discord(email:, name:, uid:)
    user = find_by(uid: uid, provider: 'discord')
    user.email = email if user

    if !user && User.where(email: email).where.not(uid: uid).first
      # TODO : add error message to user
      # account already exists (by email), but associated with a different uid
      return nil
    end

    user = find_or_initialize_by(email: email)
    user.provider = 'discord'
    user.name = name if user.name.blank?
    user.uid = uid
    user.confirm!
    user.save!

    user
  end


  # An account through which AI uses the site (see ApiToken). It has no
  # password and can't sign in to the site; an admin issues it tokens.
  def self.create_ai_account!(name:)
    create!(name: name, bot: true, confirmed_at: Time.current,
            email: "#{name.parameterize.presence || 'ai'}-#{SecureRandom.hex(4)}@#{AI_EMAIL_DOMAIN}")
  end

  # Whether the account may sign in to the site itself (as opposed to an AI
  # account using tokens).
  def can_sign_in?
    !bot? && !disabled?
  end

  def has_role?(role)
    # root has all the roles
    roles.include?(role) || roles.include?('root')
  end

  def root?
    has_role?('root')
  end

  def editor?
    has_role?('editor') || root?
  end

  # Can cleanup comments
  def moderator?
    has_role?('moderator') || root?
  end

  def to_s
    name
  end

  def null?
    false
  end

  def not_null?
    true
  end

  def disabled?
    disabled_at.present?
  end
  alias_method :disabled, :disabled?

  def disabled=(val)
    if disabled_at && !truthy?(val)
      self.disabled_at = nil
    elsif !disabled_at && truthy?(val)
      self.disabled_at = Time.now
    end
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    self.update!(confirmed_at: Time.current)
    user_key = Current.user_key
    if user_key.present?
      Comment.where(user_key: user_key).update_all(author_id: id, user_key: nil)
    end
  end

  def password_required?
    return false if bot?
    password_digest.present? || password.present? || uid.blank?
  end

  private
  def nilify_blanks
    self.roles = [] if roles.nil?
    self.roles = self.roles.select(&:present?)
  end

  def ai_accounts_have_no_password
    errors.add(:password, "can't be set on an AI account") if bot? && password_digest.present?
  end
end
