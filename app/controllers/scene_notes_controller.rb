# frozen_string_literal: true

# Root deletes a scene's transcript note on the scene page; notes are added
# through the API (Api::V1::SceneNotesController). Back on the page, Turbo
# morphs the note away.
class SceneNotesController < ApplicationController
  def destroy
    note = authorize Scene.find(params[:scene_id]).notes.find(params[:id])
    note.destroy!
    redirect_to note.scene, status: :see_other
  end
end
