class ScenesController < ApplicationController
  def index
    authorize Scene
    @filter = SceneFilter.new(filter_params)
    @scenes = @filter.filter.page(params[:page])
  end

  def show
    @scene = find_scene
    authorize @scene
  end

  def new
    @scene = Scene.new
    authorize @scene
    # defaults
    @scene.parent = Scene.find_by(parent_id: nil)
    @scene.scene_type_id = Scene::SCENE_TYPES['Adventure']
    @scene.region_id = params[:region_id]
  end

  def create
    @scene = Scene.new(permitted_params)
    authorize @scene
    if @scene.save
      flash.notice = "Scene: '#{@scene.name}' added successfully."
      redirect_to @scene
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @scene = find_scene
    authorize @scene
  end

  def update
    @scene = find_scene
    authorize @scene
    images = params[:scene][:images]
    if @scene.update(permitted_params)
      if images
        images.each { |image| @scene.images.attach(image) }
      end
      flash.notice = "Scene: '#{@scene.name}' updated successfully."
      redirect_to @scene
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @scene = authorize find_scene
    respond_to do |format|
      if att_id = params[:attachment_id]
        image = @scene.images.find(att_id)
        image.purge_later
        format.turbo_stream { render html: helpers.turbo_frame_tag(image), layout: false }
      end
      format.html { redirect_to @scene }
    end
  end

  private
  def permitted_params
    params.require(:scene).permit(
      :name, :level_id, :level_plus, :scene_type_id, :region_id, :parent_id,
      :pvp, :sota_map_id, :sota_map_parent_poi_id
    )
  end

  def find_scene
    Scene.find(params[:id])
  end

  def filter_params
    if params.key?(:scene_filter)
      params.require(:scene_filter).permit(
        :region_id, :pvp, :level_id, :scene_type_id)
    else
      {}
    end
  end
end
