# frozen_string_literal: true

module Verifiable
  extend ActiveSupport::Concern

  included do
    belongs_to :verified_by, class_name: 'User', optional: true, foreign_key: :last_verified_by_id
    scope :verified, -> { where.not(last_verified_at: nil) }
    scope :for_verification, -> {
      order(arel_table[:last_verified_at].asc.nulls_first).order(updated_at: :asc)
    }
  end

  def verified?
    last_verified_at.present?
  end

  def verify!(user)
    update!(last_verified_at: Time.current, verified_by: user)
  end

end
