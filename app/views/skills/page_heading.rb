# frozen_string_literal: true

class Views::Skills::PageHeading < Views::Skills::Base

  def initialize(activity:, with_avatar_controls:, avatars: nil)
    @activity = activity
    @with_avatar_controls = with_avatar_controls
    @avatars = avatars
  end

  def view_template
    div(class: "flex justify-between mb-0") do
      div(class: "PageTabs") do
        page_heading_tab(@activity == "adventuring", "Adventuring Skills", current_skills_path(activity: "adventuring"))
        page_heading_tab(@activity == "crafting", "Crafting Skills", current_skills_path(activity: "crafting"))
        page_heading_tab(@activity.nil?, "Basics", skills_basics_path)
      end

      if @with_avatar_controls
        div(class: "pb-2 w-min md:w-max") do
          if @avatars
            form(data: { controller: "select-nav" }) do
              strong { "Avatar:" }
              avatar_select_tag
            end
          else
            primary_button_to("create an avatar", avatars_path, size: :sm)
          end
        end
      end
    end
  end

end
