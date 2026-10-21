# frozen_string_literal: true

class Views::Skills::PageHeading < Views::Skills::Base
  include Phlex::Rails::Helpers::SelectTag

  # With +hiding+, it heads the page for choosing the avatar's hidden skills,
  # and its activity tabs stay on that page.
  def initialize(activity:, with_avatar_controls:, avatars: nil, avatar: nil, hiding: false)
    @activity = activity
    @hiding = hiding
    @with_avatar_controls = with_avatar_controls
    @avatars = avatars
    @avatar = avatar
  end

  def view_template
    # On mobile the tabs become a full-width segmented control stacked above
    # the avatar controls; from md up they're classic tabs joined to the table.
    div(class: "flex flex-col md:flex-row md:justify-between md:items-end") do
      div(class: "PageTabs") do
        page_heading_tab(@activity == "adventuring", "Adventuring", activity_path("adventuring"), suffix: " Skills")
        page_heading_tab(@activity == "crafting", "Crafting", activity_path("crafting"), suffix: " Skills")
        page_heading_tab(@activity.nil?, "Basics", skills_basics_path)
        page_heading_tab(import?, "Import", current_skills_import_path)
      end

      if @with_avatar_controls
        div(class: "flex flex-wrap items-center justify-between md:justify-end gap-2 pb-2 text-xs md:text-base") do
          if @avatars
            form(class: "flex items-center gap-1 md:gap-2", data: { controller: "select-nav", action: "change->select-nav#navigate" }) do
              strong { "Avatar:" }
              avatar_select_tag
            end
            clear_skills_button if @avatar && !import?
          else
            primary_button_to("create an avatar", avatars_path, size: :sm)
          end
        end
      end
    end
  end

  private

  # The suffix is dropped on small screens to keep the tabs on one row.
  def page_heading_tab(current, name, path, suffix: nil)
    if current
      span(class: "PageTabs-tab PageTabs-current", aria: { current: "page" }) { tab_label(name, suffix) }
    else
      a(href: path, class: "PageTabs-tab") { tab_label(name, suffix) }
    end
  end

  def tab_label(name, suffix)
    plain name
    span(class: "hidden md:inline") { suffix } if suffix
  end

  def activity_path(activity)
    @hiding ? avatar_hidden_skills_path(@avatar, activity: activity) : current_skills_path(activity: activity)
  end

  # The Import tab: pasting skill levels from the game (SkillImportsController).
  def import?
    @activity == "import"
  end

  def clear_skills_button
    destroy_button_to(
      "Clear all skills",
      avatar_clear_skills_path(@avatar, activity: @activity),
      size: :sm,
      style: "dangerOutline",
      class: "h-8 text-xs md:text-sm",
      data: { turbo_confirm: "Clear all skills for #{@avatar.name}? This sets every skill back to zero and cannot be undone." },
    )
  end

  # Choosing an avatar stays on this tab.
  def avatar_page_path(avatar)
    import? ? new_avatar_skill_import_path(avatar_id: avatar) : avatar_skills_path(avatar_id: avatar, activity: @activity)
  end

  def avatar_select_tag
    select_tag('avatar', class: 'py-0 pl-2 pr-7 md:pl-3 md:pr-10 h-8 text-xs md:text-base bg-white text-grey-700 border-grey-300 dark:bg-grey-800 dark:text-grey-100 dark:border-grey-600') do
      option(value: avatar_page_path('none'), selected: @avatar.nil?) { '~ none ~' }

      @avatars.each do |a|
        option(value: avatar_page_path(a), selected: a.id == @avatar&.id) { a.name }
      end
    end
  end

end
