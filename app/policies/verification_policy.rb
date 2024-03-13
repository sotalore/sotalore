# frozen_string_literal: true

class VerificationPolicy < ApplicationPolicy

  protected

  def has_view_role?
    has_edit_role?
  end
end
