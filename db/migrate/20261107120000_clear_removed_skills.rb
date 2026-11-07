class ClearRemovedSkills < ActiveRecord::Migration[8.1]
  # Avatars' levels (earned_skills, by site key) and hidden skills
  # (avatars.ignored_skills, by site id) for skills that are no longer in the
  # skill list: Life Warding, which `rails skills:sync` removed when it left
  # the game, and Pick Locks, removed in 2021. Nothing reads them, but they'd
  # throw off anything that adds up an avatar's levels. When the sync removes
  # another skill, copy this migration so the release clears its rows too.
  def up
    keys = Skill::BY_KEY.keys
    ids = Skill::BY_ID.keys
    raise 'The skill list is empty; not clearing every level' if keys.empty? || ids.empty?

    levels = connection.delete(<<~SQL.squish)
      DELETE FROM earned_skills WHERE skill_key NOT IN (#{keys.map { quote(_1) }.join(', ')})
    SQL
    avatars = connection.update(<<~SQL.squish)
      UPDATE avatars
      SET ignored_skills = ARRAY(SELECT id FROM unnest(ignored_skills) id WHERE id IN (#{ids.join(', ')}))
      WHERE NOT ignored_skills <@ ARRAY[#{ids.join(', ')}]::integer[]
    SQL
    say "Deleted #{levels} levels and unhid removed skills for #{avatars} avatars"
  end

  # The skills are gone, so there's nothing to put back.
  def down
  end
end
