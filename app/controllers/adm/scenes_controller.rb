# frozen_string_literal: true

# ADM → Scenes, where scenes are managed: the list (which scenes still need
# their finds imported, and what each has, see SceneFindsReport), and each
# scene's page with its details, finds, gallery and notes. The public scene
# pages only show them.
class Adm::ScenesController < AdmController
  def index
    authorize(Scene, :manage?)
    page_title 'Scenes'
    report = SceneFindsReport.new(**params.permit(:q, :region, :scene_type, :status, :sort).to_h.symbolize_keys)
    render Views::Adm::Scenes::Index.new(report: report)
  end

  def show
    scene = authorize(find_scene, :manage?)
    page_title scene.name
    render Views::Adm::Scenes::Show.new(scene: scene)
  end

  def new
    scene = authorize Scene.new(parent: Scene.find_by(parent_id: nil), scene_type_id: Scene::SCENE_TYPES['Adventure'],
                                region_id: params[:region_id])
    page_title 'New Scene'
    render Views::Adm::Scenes::New.new(scene: scene)
  end

  def create
    scene = authorize Scene.new(permitted_params)
    if scene.save
      redirect_to adm_scene_path(scene), notice: "Scene: '#{scene.name}' added."
    else
      render Views::Adm::Scenes::New.new(scene: scene), status: :unprocessable_content
    end
  end

  def edit
    scene = authorize find_scene
    page_title "Edit #{scene.name}"
    render Views::Adm::Scenes::Edit.new(scene: scene)
  end

  def update
    scene = authorize find_scene
    if scene.update(permitted_params)
      redirect_to adm_scene_path(scene), notice: "Scene: '#{scene.name}' updated."
    else
      render Views::Adm::Scenes::Edit.new(scene: scene), status: :unprocessable_content
    end
  end

  # The confirmation: what goes with the scene if it's deleted.
  def delete
    scene = authorize(find_scene, :destroy?)
    page_title "Delete #{scene.name}"
    render Views::Adm::Scenes::Delete.new(scene: scene)
  end

  # Refused while other scenes have this one as their parent.
  def destroy
    scene = authorize find_scene
    if scene.destroy
      redirect_to adm_scenes_path, notice: "Scene: '#{scene.name}' deleted.", status: :see_other
    else
      redirect_to delete_adm_scene_path(scene), alert: scene.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def find_scene
    Scene.find(params[:id])
  end

  def permitted_params
    params.require(:scene).permit(
      :name, :level_id, :level_plus, :scene_type_id, :region_id, :parent_id,
      :pvp, :sota_map_id, :sota_map_parent_poi_id
    )
  end
end
