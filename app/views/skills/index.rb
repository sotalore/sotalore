# frozen_string_literal: true

class Views::Skills::Index < Views::Skills::Base

  def initialize(activity:, skills:, avatar: nil, avatars: nil, show_all: false)
    @activity = activity
    @skills = skills
    @avatar = avatar
    @avatars = avatars
    @show_all = show_all
  end

  def view_template
    page_title("Skills")

    div(class: "mb-12 mx-2 mt-2") do
      render Views::Skills::PageHeading.new(activity: @activity, with_avatar_controls: true, avatars: @avatars)

      div(id: "skillTable", class: "SkillTable mt-0 bg-grey-100", data: { controller: "skills-rollup" }) do
        header_row
        totals_row

        @skills.each do |category, schools|
          category_row(category)

          schools.each do |school, school_skills|
            school_skills = avatar_visible_skills(@avatar, school_skills) unless @show_all
            next unless school_skills.any?

            school_row(category, school, school_skills)
          end
        end
      end
    end
  end

  private

  def header_row
    div(class: "tableRow bg-white font-bold sticky top-0") do
      div(class: "skillCell flex flex-row items-baseline") do
        span(class: "shrink mr-1") { "Skill" }
        span(class: "text-xs opacity-8 font-normal") { "(cost)" }
        div(class: "grow text-center font-normal italic text-sm") do
          if @avatar
            if @show_all
              link_to("hide ignored", avatar_skills_path(@avatar, activity: @activity))
            else
              link_to("show all", avatar_skills_path(@avatar, activity: @activity, show_all: true))
            end
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
    div(id: "totals", class: "tableRow bg-parchment-double-shaded static md:sticky md:top-10") do
      div(class: "skillCell") { @activity.upcase }
      div(class: "xpCell currentCell") { div(class: "xp currentXP") }
      div(class: "xpCell targetCell") { div(class: "xp totalXP") }
      div(class: "remainingXPCell remainingXP")
    end
  end

  def category_row(category)
    div(id: category, class: "tableRow bg-parchment-shaded static md:sticky md:top-20",
        data: { "skills-rollup-target": "member", "rollup-target": "totals" }) do
      div(class: "skillCell") { category.upcase }
      div(class: "xpCell currentCell") { span(class: "xp currentXP") }
      div(class: "xpCell targetCell") { span(class: "xp totalXP") }
      div(class: "remainingXPCell") { span(class: "remainingXP") }
    end
  end

  def school_row(category, school, school_skills)
    div(id: "#{category}-#{school}", class: "tableRow bg-parchment-color",
        data: { "skills-rollup-target": "member", "rollup-target": category }) do
      div(class: "skillCell") { school.titleize }
      div(class: "xpCell currentCell") { div(class: "xp currentXP") }
      div(class: "xpCell targetCell") { div(class: "xp totalXP") }
      div(class: "remainingXPCell") { div(class: "remainingXP") }
    end

    school_skills.each do |skill|
      render Views::Skills::Row.new(skill, @avatar)
    end
  end

end
