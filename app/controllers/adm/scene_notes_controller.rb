# frozen_string_literal: true

# Deleting a scene's transcript note, on its ADM page; notes are added
# through the API (Api::V1::SceneNotesController). Back on the page, Turbo
# morphs the note away.
class Adm::SceneNotesController < AdmController
  def destroy
    note = authorize Scene.find(params[:scene_id]).notes.find(params[:id])
    note.destroy!
    redirect_to adm_scene_path(note.scene), status: :see_other
  end
end
