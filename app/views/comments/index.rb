# frozen_string_literal: true

class Views::Comments::Index < Views::Base

  register_value_helper :params

  def initialize(comments:, parent:, moderating: false)
    @comments = comments
    @parent = parent
    @moderating = moderating
  end

  def view_template
    page_title("Comments for #{@parent}")

    layout_main_content do
      tile do
        heading

        tile_body do
          moderation_controls if @moderating

          @comments.each { |comment| render Components::Comments::Card.new(comment: comment, parent: @parent) }
          phlex_paginate @comments
        end
      end
    end
  end

  private

  def heading
    case @parent
    when nil
      if @moderating
        tile_heading("Moderate Comments")
      else
        tile_heading("All Site Comments") do
          primary_button_to("Moderate", moderate_comments_path) if policy(Comment).moderate?
        end
      end
    when :front_page
      tile_heading("Comments for the Front Page") do
        back_button_to("Return", root_url)
      end
    else
      tile_heading("Comments for #{@parent}") do
        back_button_to("Return", @parent)
      end
    end
  end

  def moderation_controls
    div(class: "flex flex-row gap-2") do
      if params[:user_owned].present?
        div(class: "p-2") { primary_button_to("Hide User Owned", moderate_comments_path(revealed: params[:revealed])) }
      else
        div(class: "p-2") { primary_button_to("Show User Owned", moderate_comments_path(revealed: params[:revealed], user_owned: true)) }
      end

      if params[:revealed].present?
        div(class: "p-2") { primary_button_to("Hide Revealed", moderate_comments_path(user_owned: params[:user_owned])) }
      else
        div(class: "p-2") { primary_button_to("Show Revealed", moderate_comments_path(revealed: true, user_owned: params[:user_owned])) }
      end
    end
  end

end
