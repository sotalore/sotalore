# frozen_string_literal: true

# A school's row in the skill table, adding up its skills' XP. With an
# avatar hiding some of the school's skills, it says how many, linking to
# where they're chosen.
class Views::Skills::SchoolRow < Views::Base

  def initialize(skills, avatar, hidden_count: 0)
    @avatar = avatar
    @hidden_count = hidden_count
    @category = skills.first.category
    @school = skills.first.school
  end

  def view_template
    div(id: "#{@category}-#{@school}", class: "tableRow bg-parchment-color dark:bg-parchment-800 dark:text-parchment-200",
        data: { "skills-rollup-target": "member", "rollup-target": @category }) do
      div(class: "skillCell") do
        plain @school.titleize
        if @avatar && @hidden_count.positive?
          link_to("#{@hidden_count} hidden", avatar_hidden_skills_path(@avatar, activity: activity), class: "ml-2 text-sm italic")
        end
      end
      div(class: "xpCell currentCell") { div(class: "xp currentXP") }
      div(class: "xpCell targetCell") { div(class: "xp totalXP") }
      div(class: "remainingXPCell") { div(class: "remainingXP") }
    end
  end

  private

  def activity
    Skill::CRAFTING.key?(@category) ? "crafting" : "adventuring"
  end

end
