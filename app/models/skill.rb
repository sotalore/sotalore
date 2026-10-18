class Skill
  include ActiveModel::Model

  class << self
    def load_skill_data
      load_skill_file(File.join(__dir__, 'skills-adventuring.json'), ADVENTURING)
      load_skill_file(File.join(__dir__, 'skills-crafting.json'), CRAFTING)
    end

    def load_skill_file(filename, container)
      JSON.parse(File.read(filename)).each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            s = Skill.new(skill.merge({ category: category, school: school, position: BY_KEY.size }))
            container[category] ||= {}
            container[category][school] ||= []
            container[category][school] << s
            BY_KEY[s.key] = s
            BY_ID[s.id] = s
            BY_GAME_ID[s.game_id] = s if s.game_id
          end
        end
      end
    end

    def find(key)
      id = Integer(key, exception: false)
      if id
        BY_ID[id]
      else
        BY_KEY[key]
      end
    end

    # The skill with the game's id (as the sl-skills plugin exports it).
    def find_by_game_id(game_id)
      BY_GAME_ID[game_id]
    end
  end

  ADVENTURING = {}
  CRAFTING = {}
  BY_KEY = {}
  BY_ID = {}
  BY_GAME_ID = {}

  # game_id and game_key are the game's id and internal name ("Deflect"), from
  # the development team's data/skill-costs.csv (see `rails skills:game_ids`).
  # position is the skill's place on the skills pages (adventuring then
  # crafting, each by category, school and skill), which is the game's order.
  attr_accessor :id, :key, :name, :xp_factor, :category, :school, :game_id, :game_key, :position

  # Total XP needed to reach a level, fit to the game's published values
  # (data/skill-costs.csv) for levels 50-200. The base curve grows 10% per
  # level, and each skill's cost is that curve scaled by its xp_factor.
  # e.g. level 200 with a 1x factor is 16_709_249_906.
  def xp_to_level(level)
    return 0 if level <= 1

    (xp_factor * ((87.98728668 * (1.1**level)) - 95.5).round).ceil
  end

end


Skill.load_skill_data
