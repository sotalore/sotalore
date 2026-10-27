class AddGatheringSkillToGatheringNodes < ActiveRecord::Migration[8.1]
  # Which skill gathers from a node (mining a vein, forestry on a tree),
  # set by an editor, so a harvest yield says how its item is gathered.
  def change
    add_column :gathering_nodes, :gathering_skill, :string
  end
end
