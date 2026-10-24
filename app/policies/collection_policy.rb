# frozen-string-literal: true

# Anyone can browse collections; editors make them and fill them, like items.
class CollectionPolicy < ApplicationPolicy

  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end
