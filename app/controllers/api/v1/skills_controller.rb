# frozen_string_literal: true

# Every skill the site knows (see Skill), with the game's id and key, so a
# client can compare them with sl-admin's list of every skill in the game
# (sotalore-game-skills.json; see GameSkillSync, which brings the site in step).
class Api::V1::SkillsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # Every skill: there are a few hundred, so no paging.
  def index
    authorize(:skill)
    render json: { skills: Skill::BY_KEY.values.map { skill_json(_1) }, game_schools: GameSkillSync::SCHOOLS }
  end

  private

  def skill_json(skill)
    { id: skill.id, key: skill.key, name: skill.name,
      activity: Skill::ADVENTURING.key?(skill.category) ? 'adventuring' : 'crafting',
      category: skill.category, school: skill.school, xp_factor: skill.xp_factor,
      game_id: skill.game_id, game_key: skill.game_key }
  end
end
