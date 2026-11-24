# frozen_string_literal: true

# A scene's gallery, on its ADM page: adding images (chosen or pasted, see
# image_upload_controller.js) and deleting them. Back on the page, Turbo
# morphs the change in. The companion adds images through the API instead
# (Api::V1::SceneImagesController).
class Adm::SceneImagesController < AdmController
  def create
    scene = authorize(find_scene, :update?)
    Array(params.dig(:scene, :images)).compact_blank.each { scene.images.attach(_1) }
    redirect_to adm_scene_path(scene), status: :see_other
  end

  def destroy
    scene = authorize(find_scene, :update?)
    scene.images.find(params[:id]).purge
    redirect_to adm_scene_path(scene), status: :see_other
  end

  private

  def find_scene
    Scene.find(params[:scene_id])
  end
end
