# Anyone can see scenes; root edits them and their galleries. AI accounts can
# add images to a gallery through the API (with a token's images scope).
class ScenePolicy < ApplicationPolicy

  def add_image?
    update? || user.bot?
  end

end
