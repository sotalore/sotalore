# frozen_string_literal: true

# Finding scenes, by the game's internal name or the site's name, so a client
# can tell which scene a screenshot belongs to before adding it (see
# Api::V1::SceneImagesController).
class Api::V1::ScenesController < Api::BaseController
  before_action -> { require_scope!('read') }

  # ?game_name= (exactly), ?name= (ignoring case), ?q= (name contains),
  # ?page=, ?per=
  def index
    authorize(Scene)
    scenes = Scene.by_name.includes(:parent, :images_attachments)
    scenes = scenes.where(game_name: params[:game_name]) if params[:game_name].present?
    scenes = scenes.where('lower(scenes.name) = ?', params[:name].downcase) if params[:name].present?
    scenes = scenes.where('scenes.name ILIKE ?', "%#{Scene.sanitize_sql_like(params[:q])}%") if params[:q].present?
    render json: paged(:scenes, scenes) { scene_json(_1) }
  end

  private

  def scene_json(scene)
    scene_ref(scene).merge(
      game_name: scene.game_name, region: scene.region, scene_type: scene.scene_type,
      level: scene.level, level_plus: scene.level_plus,
      parent: scene.parent && scene_ref(scene.parent), images: scene.images_attachments.size,
      url: scene_url(scene)
    )
  end
end
