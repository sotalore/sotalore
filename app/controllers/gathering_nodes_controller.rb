# frozen_string_literal: true

# Gathering nodes, from finds imports: where they are and what harvesting
# gives. Seen by whoever sees finds (see FindsPolicy).
class GatheringNodesController < ApplicationController
  def index
    authorize(GatheringNode)
    render Views::Creatures::Index.new(records: GatheringNode.by_name.includes(:scenes), title: 'Gathering Nodes')
  end

  def show
    node = GatheringNode.find(params[:id])
    authorize(node)
    render Views::Creatures::Show.new(record: node, links: node.scenes.map { SceneNode.new(scene: _1) })
  end
end
