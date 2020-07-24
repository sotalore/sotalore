module CraftSkillHelper

  def craft_skills_for_recipe_options
    CraftSkill::WITH_RECIPES.map do |cs|
      name = "#{cs.name} (#{cs.primary_tool})"
      [ name, cs.key ]
    end
  end

end
