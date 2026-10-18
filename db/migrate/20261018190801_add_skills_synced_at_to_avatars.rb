# frozen_string_literal: true

class AddSkillsSyncedAtToAvatars < ActiveRecord::Migration[8.1]
  def change
    add_column :avatars, :skills_synced_at, :datetime
  end
end
