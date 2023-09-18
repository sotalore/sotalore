# frozen_string_literal: true

class AddIgnoredSkillsToAvatar < ActiveRecord::Migration[7.0]
  def change
    add_column :avatars, :ignored_skills, :integer, array: true, null: false, default: []
  end
end
