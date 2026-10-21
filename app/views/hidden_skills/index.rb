# frozen_string_literal: true

# Choosing the avatar's hidden skills (HiddenSkillsController): every skill of
# the activity, by school, with its levels and a checkbox that hides it. Each
# change is saved as it's made (hidden_skills_controller.js).
class Views::HiddenSkills::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  # Only the skill name gives way on a narrow screen (wrapping); the
  # other columns keep their widths, so the rows line up.
  ROW = "flex flex-row items-center gap-x-2 px-2 py-1 md:py-2 border-b border-grey-300 dark:border-grey-700"
  LEVEL = "w-14 md:w-20 shrink-0 text-right"
  # Under the column headings (h-9 md:h-11), and over the skill rows: a
  # hidden one's opacity puts it in a layer of its own.
  STUCK_SCHOOL = "sticky top-9 md:top-11 z-10"

  def initialize(activity:, skills:, avatar:)
    @activity = activity
    @skills = skills
    @avatar = avatar
  end

  def view_template
    page_title("Hidden Skills")

    # The note comes first: above the tabs, scrolling away, until there's
    # room (xl) to keep it beside the table, where its total stays in view.
    # From md up, the tabs and the table are only as wide as the wider of
    # them needs: the tabs, or the longest skill name. On a phone they fill
    # the screen. The avatar is the one the skills page was showing, so
    # there's no avatar select; the note names it.
    div(class: "mb-12 mx-2 mt-2 md:w-fit flex flex-col xl:flex-row-reverse xl:items-start gap-x-4",
        data: { controller: "hidden-skills" }) do
      note

      div do
        render Views::Skills::PageHeading.new(activity: @activity, with_avatar_controls: false, avatar: @avatar, hiding: true)

        div(class: "mt-0 bg-grey-100 dark:bg-grey-900") do
          header_row

          @skills.each do |category, schools|
            div(class: [ ROW, "font-bold bg-parchment-shaded dark:bg-parchment-900 dark:text-parchment-100" ]) { category.upcase }

            schools.each do |school, skills|
              school_group(school, skills)
            end
          end
        end
      end
    end
  end

  private

  # Below xl, w-0 min-w-full wraps it to the table's width, rather than
  # widening the table to fit it on one line.
  def note
    div(class: "w-0 min-w-full mb-2 text-sm xl:w-64 xl:min-w-0 xl:mb-0 xl:sticky xl:top-0 xl:p-3 xl:rounded xl:bg-white xl:dark:bg-grey-800") do
      p(class: "mb-0") do
        plain "Skills hidden for "
        strong { @avatar.name }
        plain " are left off the skills page and its totals. "
        span(class: "italic xl:block xl:mt-2", data: { hidden_skills_target: "total" }) do
          hidden_text(hidden_count(@skills.values.flat_map(&:values).flatten))
        end
      end
    end
  end

  # The column headings stay in view, with each school's row stuck below
  # them (STUCK_SCHOOL) until the next school pushes it off. Their fixed
  # height is what the school rows stick under.
  def header_row
    div(class: [ ROW, "h-9 md:h-11 sticky top-0 z-20 font-bold bg-white dark:bg-grey-800" ]) do
      span(class: "w-10 shrink-0") { "Hide" }
      # Like the skills page's link here to this one.
      div(class: "grow flex flex-row items-baseline") do
        span(class: "shrink-0") { "Skill" }
        # Just "back" on a phone, to fit the row's fixed height on one line.
        div(class: "grow text-center font-normal italic text-sm whitespace-nowrap") do
          link_to(avatar_skills_path(@avatar, activity: @activity)) do
            plain "back"
            span(class: "hidden md:inline") { " to skills" }
          end
        end
      end
      span(class: LEVEL) { "Current" }
      span(class: LEVEL) { "Target" }
      span(class: "w-5 shrink-0")
    end
  end

  def school_group(school, skills)
    div(data: { hidden_skills_target: "school" }) do
      div(class: [ ROW, STUCK_SCHOOL, "flex-wrap bg-parchment-color dark:bg-parchment-800 dark:text-parchment-200" ], data: { row: true }) do
        span(class: "grow font-bold") do
          plain school.titleize
          span(class: "ml-2 text-sm font-normal italic", data: { hidden_skills_target: "count" }) { hidden_text(hidden_count(skills)) }
        end
        school_button("Hide all", school, hide_avatar_skill_school_path(@avatar, school.parameterize), hide: true)
        school_button("Reveal all", school, reveal_avatar_skill_school_path(@avatar, school.parameterize), hide: false)
        save_status
      end

      skills.each { skill_row(_1) }
    end
  end

  # A form of its own, so it works without JavaScript; with it, the
  # controller saves it in the background instead.
  def school_button(label, school, path, hide:)
    button_to(label, path, method: :patch, class: add_button_css_classes(style: "onParchment", size: :xs)[:class],
              aria: { label: "#{label} #{school.titleize} skills" },
              form: { class: "contents", data: { action: "hidden-skills#saveSchool", hidden_skills_hide_param: hide } })
  end

  # The whole row is the checkbox's label, an easy target on a phone.
  def skill_row(skill)
    hidden = @avatar.ignoring_skill?(skill)
    earned = @avatar.current_skills[skill.key]

    label(class: [ ROW, "cursor-pointer", ("opacity-50" if hidden) ], data: { row: true, hidden_skills_target: "skill" }) do
      span(class: "w-10 shrink-0 flex") do
        input(type: "checkbox", checked: hidden, class: "rounded-sm", aria: { label: "Hide #{skill.name}" },
              data: { action: "change->hidden-skills#toggle",
                      hide_url: hide_avatar_skill_path(@avatar, skill.id),
                      reveal_url: reveal_avatar_skill_path(@avatar, skill.id), })
      end
      span(class: "grow") { skill.name }
      span(class: LEVEL) { earned.current.to_s }
      span(class: LEVEL) { earned.target.to_s }
      save_status
    end
  end

  # Shows that a row's change is saving, saved, or failed to save; the
  # controller shows one of these at a time.
  def save_status
    span(class: "w-5 shrink-0 flex justify-center", data: { save_status: true }) do
      span(class: "hidden", data: { state: "saving" }, title: "Saving") { render_icon(:spinner, size: :sm, css_class: "animate-spin") }
      span(class: "hidden text-green-600 dark:text-green-400 transition-opacity duration-700", data: { state: "done" }, title: "Saved") do
        render_icon(:check, size: :sm)
      end
      span(class: "hidden text-red-600 dark:text-red-400", data: { state: "failed" }, title: "Not saved. Reload the page and try again.") do
        render_icon(:warning, size: :sm)
      end
    end
  end

  def hidden_count(skills)
    skills.count { @avatar.ignoring_skill?(_1) }
  end

  def hidden_text(count)
    count.zero? ? "" : "#{count} hidden"
  end

end
