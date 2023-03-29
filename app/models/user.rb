# frozen-string-literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one_attached :picture

  has_many :avatars, dependent: :destroy, inverse_of: :user
  has_many :user_recipes, dependent: :delete_all, inverse_of: :user
  has_many :recipes, through: :user_recipes
  has_many :plantings, inverse_of: :user, dependent: :delete_all

  ROLES = %w[ root editor moderator ]

  before_validation :nilify_blanks

  validates :name, presence: true
  validates :name, length: { in: 3..64 }
  validates :name, uniqueness: { ignore_case: true }

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

  def is?(other)
    self == other
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

  def active_for_authentication?
    super && !disabled?
  end

  private
  def nilify_blanks
    self.roles = [] if roles.nil?
    self.roles = self.roles.select(&:present?)
  end
end
