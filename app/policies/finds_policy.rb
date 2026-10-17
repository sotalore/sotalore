# frozen-string-literal: true

# Who sees what can be found where (see FindsImport): on item and scene
# pages, and the creature and gathering node pages. Admins only while
# there's too little data to look meaningful; make has_view_role? true to
# show everyone.
class FindsPolicy < ApplicationPolicy

  def show?
    has_view_role?
  end

  def index?
    has_view_role?
  end

  protected

  def has_view_role?
    user.has_role?('root')
  end

end
