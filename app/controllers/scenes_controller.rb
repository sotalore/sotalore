# The public scene pages, which only show scenes; they're managed in ADM →
# Scenes (Adm::ScenesController).
class ScenesController < ApplicationController
  def index
    authorize Scene
    @filter = SceneFilter.new(filter_params)
    @scenes = @filter.filter.page(params[:page])
    render Views::Scenes::Index.new(scenes: @scenes, filter: @filter)
  end

  def show
    @scene = Scene.find(params[:id])
    authorize @scene
    render Views::Scenes::Show.new(scene: @scene)
  end

  private

  def filter_params
    if params.key?(:scene_filter)
      params.require(:scene_filter).permit(
        :region_id, :pvp, :level_id, :scene_type_id)
    else
      {}
    end
  end
end
