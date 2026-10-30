# frozen_string_literal: true

# What a pasted skill code (SkillCode) would change on an avatar, and making
# those changes. Only current levels come from the game; targets are the
# player's, so they're raised only when asked. A skill the game doesn't list
# is untrained there: its current level is cleared, unless asked not to.
class SkillSync

  Change = Data.define(:skill, :from, :to)

  attr_reader :avatar, :code

  def initialize(avatar, code)
    @avatar = avatar
    @code = code
  end

  # Skills whose current level would change from the game's level (from is
  # nil for a skill the avatar has no level for yet). These lists are in the
  # skills pages' order.
  def changes
    @changes ||= game_levels.filter_map do |skill, level|
      from = earned(skill)&.current
      Change.new(skill, from, level) unless (from || 0) == level
    end.sort_by { _1.skill.position }
  end

  # Skills with a current level on the site that the game doesn't list.
  def untrained
    @untrained ||= avatar.skills.filter_map do |earned|
      skill = earned.skill
      Change.new(skill, earned.current, nil) if skill && earned.current.to_i.positive? && !game_levels.key?(skill)
    end.sort_by { _1.skill.position }
  end

  # Skills whose target is below the game's level.
  def above_target
    @above_target ||= game_levels.filter_map do |skill, level|
      target = earned(skill)&.target
      Change.new(skill, target, level) if target.to_i.positive? && target < level
    end.sort_by { _1.skill.position }
  end

  # Ignored skills the game says are trained.
  def ignored_trained
    @ignored_trained ||= game_levels.keys.select { avatar.ignoring_skill?(_1) && game_levels[_1].positive? }
                                         .sort_by(&:position)
  end

  # Game ids the site has no skill for.
  def unknown_ids
    code.levels.keys.reject { Skill.find_by_game_id(_1) }
  end

  def unchanged_count
    game_levels.size - changes.size
  end

  def character_matches?
    code.character.blank? || code.character.casecmp?(avatar.name)
  end

  # The player's other avatar named like the code's character, if any.
  def matching_avatar
    return if character_matches?
    avatar.user.avatars.where.not(id: avatar.id).find { _1.name.casecmp?(code.character) }
  end

  # Returns how many skills changed.
  def apply!(clear_untrained: true, raise_targets: false, reveal_ignored: false)
    Avatar.transaction do
      changes.each { |change| earned_for(change.skill).update!(current: change.to) }
      untrained.each { |change| earned_for(change.skill).update!(current: nil) } if clear_untrained
      above_target.each { |change| earned_for(change.skill).update!(target: change.to) } if raise_targets
      if reveal_ignored && ignored_trained.any?
        avatar.update!(ignored_skills: avatar.ignored_skills - ignored_trained.map(&:id))
      end
      avatar.update!(skills_synced_at: Time.current)
    end
    changes.size + (clear_untrained ? untrained.size : 0)
  end

  private

  # Skill => level, for the code's skills the site knows.
  def game_levels
    @game_levels ||= code.levels.filter_map { |id, level| [ Skill.find_by_game_id(id), level ] if Skill.find_by_game_id(id) }
                                .to_h
  end

  def earned(skill)
    earned_by_key[skill.key]
  end

  def earned_for(skill)
    earned(skill) || avatar.skills.new(skill_key: skill.key)
  end

  def earned_by_key
    @earned_by_key ||= avatar.skills.index_by(&:skill_key)
  end

end
