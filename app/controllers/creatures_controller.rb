# frozen_string_literal: true

# Creatures, from finds imports: where they live and what field dressing
# gives. Seen by whoever sees finds (see FindsPolicy).
class CreaturesController < ApplicationController
  def index
    authorize(Creature)
    creatures = Creature.by_name.includes(:scenes)
    render Views::Creatures::Index.new(records: creatures, title: 'Creatures')
  end

  def show
    creature = Creature.find(params[:id])
    authorize(creature)
    render Views::Creatures::Show.new(record: creature,
                                      links: creature.scene_creatures.includes(:scene).sort_by { _1.scene.name })
  end
end
