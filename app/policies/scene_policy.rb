# Anyone can see scenes; root manages them (adds, edits and deletes them, and
# their galleries and notes) in ADM → Scenes. AI accounts can add images to
# a gallery through the API (with a token's images scope).
class ScenePolicy < ApplicationPolicy

  # ADM's scene pages, and the public pages' link to them.
  def manage?
    has_edit_role?
  end

  def add_image?
    update? || user.bot?
  end

end
