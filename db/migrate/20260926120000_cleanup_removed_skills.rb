# frozen_string_literal: true

# Skills were brought in line with the game's current skill list
# (data/skill-costs.csv). Remove saved data for skills that no longer exist,
# and follow Pugilism's move from Subterfuge to Tactics.
class CleanupRemovedSkills < ActiveRecord::Migration[8.1]
  REMOVED_SKILLS = {
    236 => 'strategy~bard~atonal-aria',
    237 => 'strategy~bard~anthem-of-alacrity',
    238 => 'strategy~bard~rhythmic-readiness',
    239 => 'strategy~bard~psalm-of-stagnation',
    240 => 'strategy~bard~concussive-canticle',
    244 => 'strategy~bard~mesmerizing-melody',
    246 => 'strategy~bard~refrain-of-resistance',
    247 => 'strategy~bard~voice-training',
    255 => 'strategy~taming~frenzy',
    260 => 'strategy~taming~refresh',
  }.freeze

  def up
    execute <<~SQL
      DELETE FROM earned_skills
      WHERE skill_key IN (#{REMOVED_SKILLS.values.map { quote(it) }.join(', ')})
    SQL

    REMOVED_SKILLS.each_key do |id|
      execute <<~SQL
        UPDATE avatars SET ignored_skills = array_remove(ignored_skills, #{id})
        WHERE #{id} = ANY(ignored_skills)
      SQL
    end

    execute <<~SQL
      UPDATE earned_skills SET skill_key = 'strategy~tactics~pugilism'
      WHERE skill_key = 'strategy~subterfuge~pugilism'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE earned_skills SET skill_key = 'strategy~subterfuge~pugilism'
      WHERE skill_key = 'strategy~tactics~pugilism'
    SQL
  end
end
