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
            s = Skill.new(skill.merge({category: category, school: school}))
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

  def xp_to_level(level)
    if level == 0
      0
    else
      (((1.099711**(level-1)) - 1) * 100).ceil
    end
  end

end


Skill.load_skill_data
