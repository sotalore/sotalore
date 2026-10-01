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
            s = Skill.new(skill.merge({ category: category, school: school }))
            container[category] ||= {}
            container[category][school] ||= []
            container[category][school] << s
            BY_KEY[s.key] = s
            BY_ID[s.id] = s
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
  end

  ADVENTURING = {}
  CRAFTING = {}
  BY_KEY = {}
  BY_ID = {}

  attr_accessor :id, :key, :name, :xp_factor, :category, :school

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
