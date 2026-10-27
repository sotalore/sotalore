# frozen_string_literal: true

# Gathering nodes, from finds imports: where they are and what harvesting
# gives. Seen by whoever sees finds (see FindsPolicy). Editors set which
# skill gathers from each, and move creatures recorded as nodes.
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

  def edit
    node = GatheringNode.find(params[:id])
    authorize(node)
    render Views::GatheringNodes::Edit.new(node: node)
  end

  def update
    node = GatheringNode.find(params[:id])
    authorize(node)
    node.assign_attributes(node_params)
    if node.save
      redirect_to node, notice: "Saved #{node.name}."
    else
      render Views::GatheringNodes::Edit.new(node: node), status: :unprocessable_content
    end
  end

  def move_to_creatures
    node = GatheringNode.find(params[:id])
    authorize(node)
    creature = node.move_to_creatures!
    redirect_to creature, notice: "Moved #{creature.name} to the creatures."
  end

  private

  def node_params
    params.expect(gathering_node: [ :gathering_skill, :notes ]).tap do |p|
      p[:gathering_skill] = p[:gathering_skill].presence
    end
  end
end
