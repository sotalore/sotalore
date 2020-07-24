# frozen-string-literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_recipes, dependent: :delete_all, inverse_of: :user
  has_many :recipes, through: :user_recipes
  has_many :plantings, inverse_of: :user, dependent: :delete_all

  ROLES = %w[ root editor ]

  before_validation :nilify_blanks

  validates :name, presence: true
  validates :name, length: { in: 3..64 }
  validates :name, uniqueness: { ignore_case: true }

  def has_role?(role)
    # root has all the roles
    roles.include?(role) || roles.include?('root')
  end

  # Can cleanup comments
  def moderator?
    has_role?('root')
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

  private
  def nilify_blanks
    self.roles = [] if roles.nil?
    self.roles = self.roles.select(&:present?)
  end
end
