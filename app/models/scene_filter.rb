class SceneFilter
  include ActiveModel::Model
  include Truthy

  attr_accessor :region_id, :scene_type_id, :level_id, :pvp, :sort

  def filter
    @scenes = Scene.all

    if sort.nil?
      @scenes = @scenes.by_name
    end

    if level_id.present?
      @scenes = @scenes.where(level_id: level_id)
    end

    if pvp.present?
      @scenes = @scenes.where(pvp: truthy?(pvp))
    end

    if scene_type_id.present?
      @scenes = @scenes.where(scene_type_id: scene_type_id)
    end

    if region_id.present?
      @scenes = @scenes.where(region_id: region_id)
    end

    @scenes
  end
end
