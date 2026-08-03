# frozen_string_literal: true

class Views::Skills::PageHeading < Views::Skills::Base
  include Phlex::Rails::Helpers::SelectTag
  include Phlex::Rails::Helpers::LinkToUnless

  register_value_helper :request

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

  private

  def page_heading_tab(current, name, path)
    link_to_unless(current, name, path, class: "PageTabs-tab") do |tab_name|
      span(class: "PageTabs-tab PageTabs-current") { tab_name }
    end
  end

  def avatar_select_tag
    current_path = request.path

    select_tag('avatar', class: 'py-0 h-8 bg-white text-grey-700 border-grey-300 dark:bg-grey-800 dark:text-grey-100 dark:border-grey-600') do
      none_path = avatar_skills_path(avatar_id: 'none', activity: @activity)
      option(value: none_path, selected: none_path == current_path) { '~ none ~' }

      @avatars.each do |a|
        avatar_path = avatar_skills_path(avatar_id: a, activity: @activity)
        option(value: avatar_path, selected: avatar_path == current_path) { a.name }
      end
    end
  end

end
