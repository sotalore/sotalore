# frozen_string_literal: true

class Views::Skills::Index < Views::Skills::Base

  def initialize(activity:, skills:, avatar: nil, avatars: nil)
    @activity = activity
    @skills = skills
    @avatar = avatar
    @avatars = avatars
  end

  def view_template
    page_title("Skills")

    div(class: "mb-12 mx-2 mt-2") do
      render Views::Skills::PageHeading.new(activity: @activity, with_avatar_controls: true, avatars: @avatars, avatar: @avatar)

      div(id: "skillTable", class: "SkillTable mt-0 bg-grey-100 dark:bg-grey-900", data: { controller: "skills-rollup", action: "skill:change->skills-rollup#memberChanged" }) do
        header_row
        totals_row

        @skills.each do |category, schools|
          category_row(category)

          schools.each_value do |school_skills|
            visible_skills = avatar_visible_skills(@avatar, school_skills)
            next unless visible_skills.any?

            school_row(visible_skills, hidden_count: school_skills.size - visible_skills.size)
          end
        end
      end
    end
  end

  private

  def avatar_visible_skills(avatar, skills)
    return skills unless avatar

    skills.select { |s| !avatar.ignoring_skill?(s) }
  end

  def header_row
    div(class: "tableRow bg-white dark:bg-grey-800 font-bold sticky top-0") do
      div(class: "skillCell flex flex-row items-baseline") do
        div(class: 'flex flex-row items-center gap-x-1') do
          span(class: "shrink mr-1") { "Skill" }
          span(class: "text-xs font-normal") { "(cost)" }
        end
        div(class: "grow text-center font-normal italic text-sm") do
          if @avatar
            hidden = @skills.values.flat_map(&:values).flatten.count { @avatar.ignoring_skill?(_1) }
            label = hidden.zero? ? "hide skills" : "manage hidden (#{hidden})"
            link_to(label, avatar_hidden_skills_path(@avatar, activity: @activity))
          end
        end
      end
      div(class: "xpCell currentCell") do
        div(class: "level") { "Current level" }
        div(class: "xp") { "Spent XP" }
      end
      div(class: "xpCell targetCell") do
        div(class: "level") { "Target level" }
        div(class: "xp") { "Total XP" }
      end
      div(class: "remainingXPCell") { "Needed XP" }
    end
  end

  def totals_row
    div(id: "totals", class: "tableRow bg-parchment-double-shaded dark:bg-parchment-950 dark:text-parchment-100 static md:sticky md:top-10") do
      div(class: "skillCell") { @activity.upcase }
      div(class: "xpCell currentCell") { div(class: "xp currentXP") }
      div(class: "xpCell targetCell") { div(class: "xp totalXP") }
      div(class: "remainingXPCell remainingXP")
    end
  end

  def category_row(category)
    div(id: category, class: "tableRow bg-parchment-shaded dark:bg-parchment-900 dark:text-parchment-100 static md:sticky md:top-20",
        data: { "skills-rollup-target": "member", "rollup-target": "totals" }) do
      div(class: "skillCell") { category.upcase }
      div(class: "xpCell currentCell") { span(class: "xp currentXP") }
      div(class: "xpCell targetCell") { span(class: "xp totalXP") }
      div(class: "remainingXPCell") { span(class: "remainingXP") }
    end
  end

  def school_row(school_skills, hidden_count:)
    render Views::Skills::SchoolRow.new(school_skills, @avatar, hidden_count: hidden_count)

    school_skills.each do |skill|
      render Views::Skills::Row.new(skill, @avatar)
    end
  end

end
