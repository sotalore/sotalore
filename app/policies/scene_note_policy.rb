# Scene notes are private: root sees and deletes them on the scene's ADM
# page, and AI accounts add and read them through the API (with a token's
# notes scope). Nobody else, editors included, sees them.
class SceneNotePolicy < ApplicationPolicy

  def index?
    user.has_role?('root') || user.bot?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  # destroy? is root's (ApplicationPolicy), on the scene's ADM page.

end
